#!/usr/bin/env bash
# ============================================================================
# Post-install root setup. Run AFTER installing the packages (paru -S ...).
#   sudo bash ~/post-install-root.sh
#
# Does:
#   - gnome-keyring auto-unlock via PAM (targets /etc/pam.d/sddm because you
#     log in through SDDM; also /etc/pam.d/login for TTY logins).
#   - enable the ydotool daemon (for Caelestia's alternate-paste bind).
#   - (optional, commented) lid-close -> suspend-then-hibernate.
# ============================================================================
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with: sudo bash $0"; exit 1; }

add_keyring_pam() {
  local f="$1"
  [[ -f "$f" ]] || { echo "    $f not present — skipped"; return; }
  if grep -q pam_gnome_keyring "$f"; then
    echo "    $f already has pam_gnome_keyring — skipped"
    return
  fi
  cp -a "$f" "$f.bak.$(date +%s)"
  # Insert after the LAST auth line and the LAST session line. PAM groups by
  # type, so position within the type is what matters, not file order.
  awk '
    { lines[NR]=$0; if($1=="auth") la=NR; if($1=="session") ls=NR }
    END{
      for(i=1;i<=NR;i++){
        print lines[i]
        if(i==la) print "auth       optional     pam_gnome_keyring.so"
        if(i==ls) print "session    optional     pam_gnome_keyring.so auto_start"
      }
    }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "    added pam_gnome_keyring lines to $f"
}

echo "==> gnome-keyring PAM auto-unlock"
add_keyring_pam /etc/pam.d/sddm
add_keyring_pam /etc/pam.d/login

echo "==> ydotool daemon"
if   systemctl list-unit-files | grep -q '^ydotool\.service';  then
  systemctl enable --now ydotool.service;  echo "    enabled ydotool.service (system)"
elif systemctl list-unit-files | grep -q '^ydotoold\.service'; then
  systemctl enable --now ydotoold.service; echo "    enabled ydotoold.service (system)"
else
  echo "    No system ydotool unit. As YOUR user (not root) run:"
  echo "      systemctl --user enable --now ydotoold.service"
fi

echo "==> (optional) Lid close -> suspend-then-hibernate (matches your Super+Shift+L)"
echo "    Skipped by default. Uncomment the block below in this script to apply."
# install -d /etc/systemd/logind.conf.d
# cat > /etc/systemd/logind.conf.d/10-lid.conf <<'EOF'
# [Login]
# HandleLidSwitch=suspend-then-hibernate
# HandleLidSwitchExternalPower=suspend
# EOF
# echo "    wrote /etc/systemd/logind.conf.d/10-lid.conf (re-login or reboot to apply)"

echo "Done."
