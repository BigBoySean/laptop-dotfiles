#!/usr/bin/env bash
# ============================================================================
# WiFi auto-connect fix for an iwd + systemd-networkd laptop.
#
# Root cause found:
#   1) iwd.service was DISABLED -> never started at boot -> wlan0 never
#      associated -> systemd-networkd's DHCP had no carrier to work with.
#   2) Dual IP-config conflict: /etc/iwd/main.conf had
#      EnableNetworkConfiguration=true (iwd doing its own DHCP) AND
#      /etc/systemd/network/25-wireless.network had DHCP=yes (networkd doing
#      DHCP). Two managers fighting over wlan0 -> the "associated but no IP,
#      have to disconnect/reconnect" symptom. networkd should own IP here.
#
# Usage:
#   sudo bash ~/wifi-fix.sh           # apply the fix (changes take effect on reboot)
#   sudo bash ~/wifi-fix.sh test      # simulate a boot now (DISRUPTIVE) to verify
# ============================================================================
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with: sudo bash $0 [test]"; exit 1; }

SSID="Fizz0499 5G"

apply() {
  echo "==> 1. Enable iwd at boot (the primary fix — it was disabled)"
  systemctl enable iwd

  echo "==> 2. Make iwd association-only; let systemd-networkd own DHCP"
  install -d /etc/iwd
  [[ -f /etc/iwd/main.conf ]] && cp -a /etc/iwd/main.conf "/etc/iwd/main.conf.bak.$(date +%s)"
  cat > /etc/iwd/main.conf <<'EOF'
# Managed by wifi-fix.sh
# IP/DHCP is handled by systemd-networkd (/etc/systemd/network/25-wireless.network)
# and DNS by systemd-resolved, so iwd must NOT configure the network itself.
[General]
EnableNetworkConfiguration=false

[Network]
NameResolvingService=systemd
EOF

  echo "==> 3. Ensure the IP/DNS stack is enabled (idempotent)"
  systemctl enable systemd-networkd systemd-resolved

  echo "==> 4. Make sure NetworkManager/wpa_supplicant won't race (already disabled)"
  systemctl disable NetworkManager wpa_supplicant 2>/dev/null || true
  # Hard-prevent accidental re-enable (optional — uncomment if you like):
  # systemctl mask NetworkManager wpa_supplicant

  echo "==> 5. Verify the saved profile auto-connects"
  local prof="/var/lib/iwd/${SSID}.psk"
  if [[ -f "$prof" ]]; then
    if grep -q '^AutoConnect=false' "$prof"; then
      sed -i 's/^AutoConnect=false/AutoConnect=true/' "$prof"
      echo "    -> flipped AutoConnect to true"
    else
      echo "    -> AutoConnect OK (iwd defaults to true unless explicitly false)"
    fi
  else
    echo "    !! No saved profile at: $prof"
    echo "       Existing profiles:"; ls -1 /var/lib/iwd/ 2>/dev/null || true
    echo "       If missing, connect once: iwctl station wlan0 connect \"$SSID\""
  fi

  echo
  echo "Applied. Enablement now:"
  systemctl is-enabled iwd systemd-networkd systemd-resolved
  echo "Reboot to confirm WiFi comes up automatically."
}

simulate() {
  echo "==> Simulating a fresh boot for wlan0 (this WILL drop your connection)..."
  systemctl stop iwd 2>/dev/null || true
  ip addr flush dev wlan0 2>/dev/null || true
  ip link set wlan0 down 2>/dev/null || true
  sleep 1
  ip link set wlan0 up 2>/dev/null || true
  systemctl restart systemd-networkd
  systemctl start iwd
  echo "Waiting up to 25s for auto-associate + DHCP (no manual connect)..."
  for _ in $(seq 1 25); do
    ip -4 addr show wlan0 2>/dev/null | grep -q 'inet ' && break
    sleep 1
  done
  echo "--- wlan0 ---"; ip -br addr show wlan0
  echo "--- iwd log ---"; journalctl -u iwd -n 12 --no-pager
  echo "--- connectivity ---"; ping -c2 -W3 1.1.1.1 || echo "(no ping yet)"
  echo "If wlan0 has an inet address above with NO manual 'station connect', the reboot will work."
}

case "${1:-apply}" in
  test|simulate) simulate ;;
  *)             apply ;;
esac
