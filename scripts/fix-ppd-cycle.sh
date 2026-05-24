#!/usr/bin/env bash
# =============================================================================
# fix-ppd-cycle.sh
#
# Fixes an unfixable systemd ordering cycle introduced by tune-power.sh's
# ppd-ac-switch.service:
#
#   ppd-ac-switch.service  --After-->  power-profiles-daemon.service
#   power-profiles-daemon  --After-->  multi-user.target        (upstream PPD unit)
#   multi-user.target      --After-->  ppd-ac-switch.service    (because it's
#                                       WantedBy=multi-user.target)
#
# => closed loop. systemd logs "Transaction order is cyclic" and deletes
#    ppd-ac-switch's boot job, so it has NEVER run at boot (ActiveEnterTimestamp
#    empty). It also poisons ANY transaction that pulls in multi-user.target —
#    which is why `systemctl enable --now NetworkManager` blew up.
#
# THE FIX: stop ordering ppd-ac-switch *before* multi-user.target while keeping
# it *after* power-profiles-daemon. We do that by changing its [Install] from
#   WantedBy=multi-user.target   ->   WantedBy=power-profiles-daemon.service
# so it is pulled in (and ordered right after) PPD itself — exactly what an
# "apply the correct profile once PPD is up" oneshot wants — with no multi-user
# ordering edge, so the loop disappears.
#
# Idempotent. Self-verifying: if the cycle is somehow still present after the
# edit, it restores the original unit and aborts.
#
# USAGE (run yourself; needs interactive sudo):
#     sudo bash ~/fix-ppd-cycle.sh
# =============================================================================
set -uo pipefail

UNIT="/etc/systemd/system/ppd-ac-switch.service"
BACKUP_ROOT="/root/ppd-cycle-fix-backups"
OLD_LINE="WantedBy=multi-user.target"
NEW_LINE="WantedBy=power-profiles-daemon.service"

c_b=$'\033[1;34m'; c_g=$'\033[1;32m'; c_y=$'\033[1;33m'; c_r=$'\033[1;31m'; c_0=$'\033[0m'
info() { printf '%s==>%s %s\n'  "$c_b" "$c_0" "$*"; }
ok()   { printf '%s ok %s %s\n' "$c_g" "$c_0" "$*"; }
warn() { printf '%swarn%s %s\n' "$c_y" "$c_0" "$*" >&2; }
err()  { printf '%serr %s %s\n' "$c_r" "$c_0" "$*" >&2; }

[ "$(id -u)" -eq 0 ] || { err "Run with sudo: sudo bash $0"; exit 1; }
[ -f "$UNIT" ]       || { err "$UNIT not found — nothing to fix."; exit 1; }

# Already fixed?
if grep -qxF "$NEW_LINE" "$UNIT"; then
  ok "Already fixed ($NEW_LINE present). Re-checking for cycles anyway."
else
  if ! grep -qxF "$OLD_LINE" "$UNIT"; then
    err "Expected line '$OLD_LINE' not found in $UNIT. Aborting so I don't mangle a hand-edited unit."
    err "Current [Install] section:"; sed -n '/\[Install\]/,$p' "$UNIT" >&2
    exit 1
  fi

  mkdir -p "$BACKUP_ROOT"
  BACKUP="$BACKUP_ROOT/ppd-ac-switch.service.$(date +%Y%m%d-%H%M%S).bak"
  cp -a "$UNIT" "$BACKUP"
  ok "Backed up original unit -> $BACKUP"

  # Drop the old enablement symlink (read from the CURRENT [Install]) first.
  info "Disabling ppd-ac-switch (removes old multi-user.target.wants symlink)"
  systemctl disable ppd-ac-switch.service >/dev/null 2>&1

  info "Rewriting [Install]: $OLD_LINE -> $NEW_LINE"
  sed -i "s|^${OLD_LINE}\$|${NEW_LINE}|" "$UNIT"
  grep -qxF "$NEW_LINE" "$UNIT" || { err "edit failed; restoring backup"; cp -a "$BACKUP" "$UNIT"; systemctl daemon-reload; systemctl enable ppd-ac-switch.service >/dev/null 2>&1; exit 1; }

  systemctl daemon-reload
  info "Re-enabling ppd-ac-switch (creates power-profiles-daemon.service.wants symlink)"
  systemctl enable ppd-ac-switch.service >/dev/null 2>&1
fi

systemctl daemon-reload

# ---- Verify the cycle is gone --------------------------------------------
# Real test: actually try to start it. Before the fix, the start transaction
# fails with "Transaction order is cyclic"; after, it should succeed (and it
# harmlessly applies the correct power profile right now).
info "Verifying: starting ppd-ac-switch.service (also applies current profile)"
start_out="$(systemctl start ppd-ac-switch.service 2>&1)"
start_rc=$?
if echo "$start_out" | grep -qi 'cyclic\|ordering cycle'; then
  err "STILL CYCLIC after edit:"; echo "$start_out" >&2
  if [ -n "${BACKUP:-}" ] && [ -f "${BACKUP:-/nonexistent}" ]; then
    warn "Restoring original unit from $BACKUP"
    systemctl disable ppd-ac-switch.service >/dev/null 2>&1
    cp -a "$BACKUP" "$UNIT"
    systemctl daemon-reload
    systemctl enable ppd-ac-switch.service >/dev/null 2>&1
  fi
  err "Reverted. Cycle not fixed — do not proceed to the WiFi migration."
  exit 1
fi

if [ "$start_rc" -ne 0 ]; then
  warn "ppd-ac-switch start returned rc=$start_rc (not a cycle though):"
  echo "$start_out" >&2
  warn "Cycle is broken, but the script itself may have an unrelated issue — check:"
  warn "    systemctl status ppd-ac-switch.service ; journalctl -xeu ppd-ac-switch.service"
fi

# Cross-check the broader transaction is clean now.
if systemd-analyze verify multi-user.target 2>&1 | grep -qi 'cycle'; then
  warn "systemd-analyze still reports a cycle somewhere in multi-user.target — review above."
else
  ok "No ordering cycle reported for multi-user.target."
fi

echo
ok "=============================  PPD CYCLE FIXED  ============================="
echo "  * $UNIT [Install] -> $NEW_LINE"
echo "  * ppd-ac-switch.service now runs right after power-profiles-daemon (boot"
echo "    + on PPD restart) and is no longer ordered before multi-user.target."
[ -n "${BACKUP:-}" ] && echo "  * backup: $BACKUP"
echo
echo "Side benefit: your AC/battery auto-switcher will now actually run at boot"
echo "(it never did before — the cycle deleted its boot job every time)."
echo
echo "Next: you can now run the WiFi migration:"
echo "    sudo bash ~/switch-to-networkmanager.sh"
