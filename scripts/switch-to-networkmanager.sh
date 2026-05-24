#!/usr/bin/env bash
# =============================================================================
# switch-to-networkmanager.sh   (v2 — cyclic-dependency-safe cutover)
#
# Migrate this laptop from "iwd + systemd-networkd + systemd-resolved" to
# "NetworkManager (UX) with iwd as the wifi backend", so Caelestia's nmcli-only
# wifi widget works. iwd stays as the radio/association layer; resolved stays as
# the DNS resolver (NM feeds it via dns=systemd-resolved); only systemd-networkd
# is retired (NM takes over IP/DHCP for wlan0).
#
# WHY v2: v1 started NM while networkd was still enabled, which entangled NM's
# start with multi-user.target and tripped a pre-existing ordering cycle
# ("Transaction order is cyclic"). v2 NEVER has both enabled when anything
# starts: it configures NM WITHOUT starting it, then does a tight cutover where
# networkd is disabled+stopped and NM is enabled+started in immediate
# succession, with a daemon-reload in between. (Run fix-ppd-cycle.sh first — that
# removes the actual cycle; this ordering is belt-and-suspenders on top.)
#
# RISK PROFILE: Brief offline window of up to ~20 seconds during cutover (NM
# associates via iwd + does DHCP). Auto-rollback restores connectivity in <30s
# on any failure. iwd is NEVER disabled; /var/lib/iwd/ is NEVER touched/deleted.
# The Wi-Fi password is held only in memory during script execution (read at the
# start, used once to bootstrap NM's saved profile), never written to disk.
#
# USAGE (run yourself, in a real terminal — needs interactive sudo):
#     sudo bash ~/switch-to-networkmanager.sh            # do the migration
#     sudo bash ~/switch-to-networkmanager.sh rollback   # undo, restore iwd-only
# =============================================================================
set -uo pipefail   # NOT -e: we handle failures explicitly so rollback can run.

# ---- settings --------------------------------------------------------------
SSID="Fizz0499 5G"
WLAN="wlan0"
BACKUP_ROOT="/root/switch-to-nm-backups"
NETWORKD_FILE="/etc/systemd/network/25-wireless.network"
IWD_MAIN="/etc/iwd/main.conf"
NM_CONFD="/etc/NetworkManager/conf.d"
NM_WIFI_BACKEND="$NM_CONFD/wifi-backend.conf"
NM_DNS="$NM_CONFD/dns.conf"
CUTOVER_TIMEOUT=30   # seconds to wait for NM to get us online before failing

# ---- pretty output ---------------------------------------------------------
c_b=$'\033[1;34m'; c_g=$'\033[1;32m'; c_y=$'\033[1;33m'; c_r=$'\033[1;31m'; c_0=$'\033[0m'
info() { printf '%s==>%s %s\n'  "$c_b" "$c_0" "$*"; }
ok()   { printf '%s ok %s %s\n' "$c_g" "$c_0" "$*"; }
warn() { printf '%swarn%s %s\n' "$c_y" "$c_0" "$*" >&2; }
err()  { printf '%serr %s %s\n' "$c_r" "$c_0" "$*" >&2; }

require_root() { [ "$(id -u)" -eq 0 ] || { err "Run with sudo: sudo bash $0 ${1:-}"; exit 1; }; }

# ---- shared probes ---------------------------------------------------------
has_ipv4()     { ip -4 addr show "$WLAN" 2>/dev/null | grep -q 'inet '; }
ping_ip()      { ping -c 2 -W 3 1.1.1.1   >/dev/null 2>&1; }
ping_dns()     { ping -c 2 -W 3 github.com >/dev/null 2>&1; }
nm_connected() { [ "$(nmcli -t -f STATE general 2>/dev/null)" = "connected" ]; }
latest_backup(){ ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | sort | tail -1; }

# =============================================================================
# ROLLBACK  — also runnable on its own: sudo bash <script> rollback
#   Restores iwd-only + networkd + resolved. Must be robust AND must work from a
#   HALFWAY cutover state (networkd disabled/stopped, NM enabled/started, or any
#   partial mix). So it forces the desired end-state idempotently rather than
#   assuming where the migration stopped.
# =============================================================================
do_rollback() {
  local bdir="${1:-}"
  [ -n "$bdir" ] || bdir="$(latest_backup)"
  warn "ROLLBACK starting (backup dir: ${bdir:-none found})"

  # Drop any NM profile for this SSID while NM might still be up (inert later).
  if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$SSID" \
      && nmcli connection delete "$SSID" >/dev/null 2>&1 && info "removed NM profile '$SSID'"
  fi

  info "disabling + stopping NetworkManager (idempotent)"
  systemctl disable --now NetworkManager >/dev/null 2>&1

  info "removing NM conf.d drop-ins"
  rm -f "$NM_WIFI_BACKEND" "$NM_DNS" 2>/dev/null

  # Restore backed-up files if present (forward path doesn't edit these, but
  # restore anyway for a faithful revert).
  if [ -n "$bdir" ] && [ -d "$bdir" ]; then
    [ -f "$bdir/25-wireless.network" ] && cp -a "$bdir/25-wireless.network" "$NETWORKD_FILE" && info "restored $NETWORKD_FILE"
    [ -f "$bdir/iwd-main.conf" ]       && cp -a "$bdir/iwd-main.conf" "$IWD_MAIN"           && info "restored $IWD_MAIN"
  else
    warn "no backup dir found — leaving existing $NETWORKD_FILE / $IWD_MAIN in place"
  fi

  # Clear any transient dependency state, then force networkd + resolved back on.
  systemctl daemon-reload
  info "re-enabling + starting systemd-networkd + systemd-resolved (idempotent)"
  systemctl enable --now systemd-resolved >/dev/null 2>&1
  systemctl enable --now systemd-networkd >/dev/null 2>&1

  # Restart iwd so it drops any NM control and resumes its own autoconnect, then
  # nudge it onto the known network (uses iwd's stored PSK — no password needed).
  info "restarting iwd to resume standalone autoconnect"
  systemctl restart iwd >/dev/null 2>&1
  sleep 2
  # If a password was typed this run, hand it to iwd so it can reconnect even if
  # its known-network state got scrubbed. Standalone rollback (no password typed)
  # falls back to iwd's stored creds. (${WIFI_PSK:-} keeps this safe under set -u.)
  if [ -n "${WIFI_PSK:-}" ]; then
    iwctl --passphrase "$WIFI_PSK" station "$WLAN" connect "$SSID" >/dev/null 2>&1 || true
  else
    iwctl station "$WLAN" connect "$SSID" >/dev/null 2>&1 || true
  fi

  # Wait for the legacy path to recover.
  local i
  for i in $(seq 1 "$CUTOVER_TIMEOUT"); do
    if has_ipv4 && ping_ip; then ok "legacy path back online after ${i}s"; break; fi
    sleep 1
  done

  echo
  if ping_ip; then
    ok  "Rolled back to iwd-only setup. Network should be restored."
    ping_dns && ok "DNS works too (ping github.com)." || warn "IPv4 up but DNS check failed — give resolved a few seconds."
  else
    err "Rolled back, but wlan0 is not pinging yet. Try:  sudo systemctl restart iwd systemd-networkd"
    err "Manual reconnect (uses stored creds, no password):  iwctl station $WLAN connect \"$SSID\""
  fi
}

# fail(): print reason, run rollback, exit non-zero.
fail() {
  echo; err "MIGRATION FAILED: $*"
  err "Rolling back automatically to restore your connection..."
  do_rollback "${RUN_DIR:-}"
  echo
  err "Done rolling back. The switch did NOT take effect; you're back on iwd-only."
  err "If NM could not reuse iwd's stored PSK, complete the switch later by re-running"
  err "this script and — if it stalls at the connect step — connecting once by hand:"
  err "    nmcli device wifi connect \"$SSID\" password '<YOUR_WIFI_PASSWORD>'"
  exit 1
}

# =============================================================================
# FORWARD MIGRATION
# =============================================================================
do_migrate() {
  # ---- Wi-Fi password (in-memory only; before any system changes) ----------
  # NM's iwd backend can't reuse iwd's stored PSK during this first bootstrap, so
  # NM does the initial connect itself with the password to create its own saved
  # profile. Held only in the WIFI_PSK shell variable; never written to disk.
  read -s -p "Enter password for '$SSID' (will be used ONCE to bootstrap NM's profile, then forgotten): " WIFI_PSK; echo
  [ -n "$WIFI_PSK" ] || { err "No password entered. Aborting (nothing changed)."; exit 1; }

  # ---- A. Preflight & backups ----------------------------------------------
  info "Preflight: confirming we're online before touching anything"
  ping_ip || { err "Not online (ping 1.1.1.1 failed). Aborting — won't start a migration while offline."; exit 1; }
  ok "online (ping 1.1.1.1 ok)"
  command -v nmcli >/dev/null || { err "nmcli not found"; exit 1; }
  command -v iwctl >/dev/null || { err "iwctl not found"; exit 1; }

  RUN_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$RUN_DIR" || { err "cannot create backup dir $RUN_DIR"; exit 1; }
  info "Backups -> $RUN_DIR"
  [ -f "$NETWORKD_FILE" ] && cp -a "$NETWORKD_FILE" "$RUN_DIR/25-wireless.network"
  [ -f "$IWD_MAIN" ]      && cp -a "$IWD_MAIN"      "$RUN_DIR/iwd-main.conf"
  [ -d /etc/NetworkManager ] && cp -a /etc/NetworkManager "$RUN_DIR/NetworkManager.etc" 2>/dev/null
  systemctl is-enabled iwd systemd-networkd systemd-resolved NetworkManager > "$RUN_DIR/unit-states.before.txt" 2>&1

  iwctl known-networks list > "$RUN_DIR/iwd-known-networks.txt" 2>&1 || true
  if ls /var/lib/iwd/ 2>/dev/null | grep -qiF "Fizz0499"; then
    ok "iwd profile for '$SSID' present in /var/lib/iwd/ (contents not shown)"
  else
    warn "Could not see a Fizz0499 file in /var/lib/iwd/ by name (iwd may hex-encode it)."
    warn "known-networks snapshot saved to $RUN_DIR/iwd-known-networks.txt"
  fi
  ok "Backups complete."

  # ---- B. Install + configure NetworkManager (iwd backend) — DO NOT START ---
  info "Ensuring networkmanager is installed (no-op if already present)"
  pacman -S --needed --noconfirm networkmanager || { err "pacman install failed"; exit 1; }

  info "Writing NM drop-ins (iwd backend + systemd-resolved DNS)"
  mkdir -p "$NM_CONFD"
  printf '[device]\nwifi.backend=iwd\n'   > "$NM_WIFI_BACKEND"
  printf '[main]\ndns=systemd-resolved\n' > "$NM_DNS"
  ok "wrote $NM_WIFI_BACKEND and $NM_DNS"
  warn "NOTE: NetworkManager is configured but intentionally NOT started yet."
  warn "      It starts only inside the tight cutover below (never while networkd is enabled)."

  # ---- D. The cutover (tight) ----------------------------------------------
  # RISK: brief offline window of up to ~20s here while NM associates via iwd and
  # gets DHCP. Auto-rollback restores connectivity in <30s on any failure.
  #
  # Ordering rationale: do the enable/disable bookkeeping FIRST (no --now, so
  # nothing starts/stops yet), daemon-reload to settle the dependency graph, and
  # only THEN actually stop networkd and start NM. By the time anything is
  # *starting*, exactly one of {networkd, NetworkManager} is enabled — so the
  # start transaction can't form the cyclic state that killed v1.
  echo
  info "CUTOVER (tight): handing wlan0 from systemd-networkd to NetworkManager."
  warn "Expect ~15-20s offline here while NM associates + DHCPs. Sit tight."
  systemctl disable systemd-networkd  || fail "could not disable systemd-networkd"
  systemctl enable  NetworkManager    || fail "could not enable NetworkManager"
  systemctl daemon-reload
  systemctl stop    systemd-networkd  || fail "could not stop systemd-networkd"
  systemctl start   NetworkManager    || fail "NetworkManager failed to start (see: journalctl -xeu NetworkManager)"
  ok "networkd disabled+stopped; NetworkManager enabled+started"

  # (systemd-resolved is intentionally LEFT RUNNING; NM feeds it via dns.conf.)
  nmcli device set "$WLAN" managed yes >/dev/null 2>&1 || true
  nmcli device wifi rescan ifname "$WLAN" >/dev/null 2>&1 || true
  sleep 2
  # First connection: NM associates with the password itself (one-time). The iwd
  # backend can't reuse iwd's stored PSK during this bootstrap, so we hand NM the
  # password directly. This creates a SAVED NM profile that auto-reconnects on
  # future boots (no password needed thereafter).
  info "Connecting '$SSID' with the supplied password (creates NM's saved profile)"
  nmcli device wifi connect "$SSID" password "$WIFI_PSK" ifname "$WLAN" hidden no >/dev/null 2>&1 || true

  # ---- E. Verification (gate; failure => auto rollback) --------------------
  info "Waiting up to ${CUTOVER_TIMEOUT}s for NM to associate + get DHCP..."
  local i
  for i in $(seq 1 "$CUTOVER_TIMEOUT"); do
    if nm_connected && has_ipv4 && ping_ip; then break; fi
    [ "$i" -eq 8 ] && nmcli device wifi connect "$SSID" password "$WIFI_PSK" ifname "$WLAN" hidden no >/dev/null 2>&1   # one nudge
    sleep 1
  done

  nm_connected || fail "NM never reached state=connected"
  ok "nmcli general: connected"
  has_ipv4     || fail "$WLAN has no IPv4 address"
  ok "$WLAN has an IPv4 address ($(ip -4 -o addr show "$WLAN" | awk '{print $4}' | head -1))"
  ping_ip      || fail "no IPv4 connectivity (ping 1.1.1.1 failed)"
  ok "IPv4 path works (ping 1.1.1.1)"
  ping_dns     || fail "DNS path failed (ping github.com) — resolved not getting NM's servers?"
  ok "DNS path works (ping github.com)"

  # Best-effort: confirm a *saved* profile exists so autoconnect survives reboot.
  if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$SSID"; then
    ok "Saved NM profile '$SSID' exists (will autoconnect on boot)."
    PROFILE_PERSISTED=yes
  else
    PROFILE_PERSISTED=no
    warn "Connected, but no *saved* NM profile named '$SSID' was created."
    warn "Auto-connect on next boot may not happen until you save one:"
    warn "    nmcli device wifi connect \"$SSID\" password '<YOUR_WIFI_PASSWORD>'"
  fi

  # ---- G. Final report (success) -------------------------------------------
  echo
  ok "=========================  MIGRATION SUCCEEDED  ========================="
  echo "NetworkManager now owns wlan0 (IP+DHCP); iwd is the wifi backend;"
  echo "systemd-resolved still does DNS (NM feeds it). systemd-networkd retired."
  echo
  echo "Changed:"
  echo "  + created  $NM_WIFI_BACKEND   (wifi.backend=iwd)"
  echo "  + created  $NM_DNS            (dns=systemd-resolved)"
  echo "  * enabled  NetworkManager.service"
  echo "  * disabled systemd-networkd.service   (was: enabled+active)"
  echo "  = kept     iwd.service  (backend, still enabled)"
  echo "  = kept     systemd-resolved.service   (still enabled)"
  echo "  = untouched /var/lib/iwd/  (profile reused, not deleted)"
  echo "  = untouched /etc/iwd/main.conf, $NETWORKD_FILE (backed up only)"
  [ "$PROFILE_PERSISTED" = no ] && echo "  ! NOTE: no saved NM profile yet — see warning above to persist autoconnect."
  echo
  echo "Backups: $RUN_DIR"
  echo
  echo "RECOVERY if WiFi breaks (e.g. on next boot):"
  echo "  Boot to a console (hold Space at the bootloader -> a working/Safe entry,"
  echo "  or Ctrl+Alt+F2 to a TTY and log in), then run:"
  echo "      sudo bash ~/switch-to-networkmanager.sh rollback"
  echo
  echo "TEST NOW: open the Caelestia bar wifi widget — it should show '$SSID' and"
  echo "let you pick other networks. Click it to confirm."

  # Scrub the password from memory now that NM has its own saved profile.
  unset WIFI_PSK
}

# =============================================================================
# entry point
# =============================================================================
case "${1:-migrate}" in
  rollback) require_root rollback; do_rollback ;;
  migrate)  require_root;          do_migrate  ;;
  *) err "Unknown argument '$1'. Use: (no args) to migrate, or 'rollback'."; exit 1 ;;
esac
