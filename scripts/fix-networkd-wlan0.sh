#!/usr/bin/env bash
# ============================================================================
# Fix: systemd-networkd was ignoring /etc/systemd/network/25-wireless.network
# because the [Match] key was lowercase `name=` (systemd requires `Name=`).
# Result: wlan0 was "unmanaged" -> no DHCPv4 -> IPv4 down (IPv6/SLAAC masked it).
# This realizes the intended "networkd owns DHCP, iwd association-only" design.
#
#   sudo bash ~/fix-networkd-wlan0.sh
# ============================================================================
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with: sudo bash $0"; exit 1; }

f=/etc/systemd/network/25-wireless.network
cp -a "$f" "$f.bak.$(date +%s)"
sed -i 's/^[[:space:]]*name=/Name=/' "$f"
echo "--- corrected $f ---"; cat "$f"

networkctl reload
networkctl reconfigure wlan0 || true

echo "Waiting up to 20s for DHCPv4 lease..."
for _ in $(seq 1 20); do
  ip -4 addr show wlan0 | grep -q 'inet ' && break
  sleep 1
done

echo "--- wlan0 now ---"; ip -br addr show wlan0
echo "--- networkd view (should be 'configured', Network File set) ---"
networkctl status wlan0 2>/dev/null | grep -E 'Network File|State'
ping -c2 -W3 1.1.1.1 >/dev/null 2>&1 && echo "IPv4 internet: OK" || echo "IPv4 internet: still no reply (check 'journalctl -u systemd-networkd')"
