#!/usr/bin/env bash
#
# tune-power.sh — software-side power tuning
# Target:  Dell Inspiron 7586  (Arch Linux + Hyprland / Caelestia, intel_pstate, Intel UHD 620)
# Staged:  2026-05-24   —   REVIEW FIRST, then run:   sudo bash ~/tune-power.sh
#
# WHY THIS DEVIATES FROM A PLAIN "INSTALL TLP" SCRIPT
#   * The battery is worn out — ~5.3% of design capacity (see ~/setup-snapshot.md).
#     No software change restores meaningful runtime; this only trims a couple of minutes.
#   * power-profiles-daemon (ppd) is ALREADY installed as a HARD DEPENDENCY of
#     caelestia-shell, so it cannot be removed without breaking Caelestia.
#   * TLP and ppd fight over the same power knobs, so installing TLP would mean masking
#     ppd's service (risking Caelestia's power widget). Per your choice we SKIP TLP and
#     drive ppd instead: power-saver on battery, balanced on AC (auto-switched).
#
# WHAT THIS SCRIPT DELIBERATELY DOES NOT DO (by request)
#   * Does NOT install tlp / tlp-rdw.
#   * Does NOT mask systemd-rfkill (that is a TLP-only recommendation; N/A for ppd).
#   * Does NOT remove power-profiles-daemon (caelestia-shell needs it).
#   * Does NOT touch brightness control            (Caelestia owns it).
#   * Does NOT touch WiFi power management / iwd    (configured separately — left alone).
#   * Does NOT reboot or restart your session.
#
# It is idempotent and reversible (revert instructions printed at the end).

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must run as root.  Try:  sudo bash $0" >&2
  exit 1
fi

log() { printf '\n=== %s ===\n' "$*"; }

PPCTL=/usr/bin/powerprofilesctl
SWITCH=/usr/local/bin/ppd-ac-switch
UNIT=/etc/systemd/system/ppd-ac-switch.service
UDEV=/etc/udev/rules.d/99-ppd-ac-switch.rules

# --- 1. powertop (official repo) — for live diagnostics later -----------------
log "Installing powertop (official repo)"
pacman -S --needed --noconfirm powertop

# --- 2. ensure power-profiles-daemon is present, unmasked, enabled -------------
log "Ensuring power-profiles-daemon is available at boot"
if ! pacman -Qq power-profiles-daemon >/dev/null 2>&1; then
  echo "(unexpected) ppd not installed — installing from official repo"
  pacman -S --needed --noconfirm power-profiles-daemon
fi
systemctl unmask power-profiles-daemon.service 2>/dev/null || true
systemctl enable --now power-profiles-daemon.service

# --- 3. AC/battery profile switcher -------------------------------------------
# balanced on AC (== EPP balance_performance), power-saver on battery (== EPP power).
log "Installing profile switcher -> $SWITCH"
install -d /usr/local/bin
cat > "$SWITCH" <<'EOS'
#!/usr/bin/env bash
# Pick ppd profile from AC state: balanced on AC, power-saver on battery.
set -u
on_ac=0
for f in /sys/class/power_supply/*/type; do
  d=$(dirname "$f")
  if [ "$(cat "$f" 2>/dev/null)" = "Mains" ] && [ "$(cat "$d/online" 2>/dev/null)" = "1" ]; then
    on_ac=1; break
  fi
done
if [ "$on_ac" = "1" ]; then target=balanced; else target=power-saver; fi
# fall back to balanced if the chosen profile is somehow unavailable
/usr/bin/powerprofilesctl list 2>/dev/null | grep -q "$target" || target=balanced
exec /usr/bin/powerprofilesctl set "$target"
EOS
chmod +x "$SWITCH"

# --- 4. systemd oneshot (runs at boot and on demand from udev) ----------------
log "Installing systemd unit -> $UNIT"
cat > "$UNIT" <<EOF
[Unit]
Description=Set power-profiles-daemon profile by AC/battery state
After=power-profiles-daemon.service
Wants=power-profiles-daemon.service

[Service]
Type=oneshot
ExecStart=$SWITCH

[Install]
WantedBy=multi-user.target
EOF

# --- 5. udev rule: re-apply whenever the AC adapter changes -------------------
log "Installing udev rule -> $UDEV"
cat > "$UDEV" <<'EOF'
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/systemctl --no-block restart ppd-ac-switch.service"
EOF

# --- 6. activate --------------------------------------------------------------
log "Activating"
systemctl daemon-reload
udevadm control --reload-rules
systemctl enable ppd-ac-switch.service
systemctl start ppd-ac-switch.service   # apply immediately for the current AC state

# --- 7. honest summary --------------------------------------------------------
CUR=$("$PPCTL" get 2>/dev/null || echo '?')
log "Summary"
cat <<EOF
ppd active profile now : $CUR
Mechanism              : balanced on AC, power-saver on battery
                         (auto-switched by udev -> ppd-ac-switch.service)

Left untouched (as requested):
  - brightness control            (Caelestia)
  - WiFi power management / iwd
  - power-profiles-daemon package  (caelestia-shell dependency — kept)
Not done (TLP-only, not applicable here):
  - tlp / tlp-rdw NOT installed
  - systemd-rfkill NOT masked
Installed:
  - powertop  ->  run:  sudo powertop      (live diagnostics)
                        sudo powertop --auto-tune   (apply its suggestions; test first)

------------------------------------------------------------------------------
HONEST ASSESSMENT
------------------------------------------------------------------------------
Battery health        : ~5.3%   (charge_full 195 mAh of 3684 mAh design)
Measured idle draw    : ~10.5 W (under light load — browser/compositor running)
Usable energy now     : ~2.2 Wh  ->  ~13 min computed, ~15 min observed = MATCH
Drain anomalies       : NONE. The ~15 min runtime is fully explained by lost
                        capacity; nothing is abnormally draining the battery.

Realistic gain from this tuning: a couple of minutes, at most. Even halving idle
draw to ~5 W only moves runtime from ~13 min to ~26 min on a 2.2 Wh pack.

>>> RECOMMENDATION: REPLACE THE BATTERY. <<<
Software cannot fix a cell that holds 5% of its original charge. This is the same
symptom you saw on Windows, which confirms hardware degradation, not the OS.

------------------------------------------------------------------------------
TO REVERT THIS TUNING
------------------------------------------------------------------------------
  systemctl disable --now ppd-ac-switch.service
  rm -f $UNIT $UDEV $SWITCH
  systemctl daemon-reload && udevadm control --reload-rules
  # (powertop and power-profiles-daemon are left installed)
EOF
