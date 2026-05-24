#!/usr/bin/env bash
# =============================================================================
# clean-efi-entries.sh
#
# Remove three DEAD UEFI boot entries from NVRAM on this Arch laptop and add a
# proper named "Arch Linux" entry, without touching any files on the ESP.
#
#   Boot0000* Windows Boot Manager  -> \EFI\Microsoft\...  (dir absent = dead)
#   Boot0001  ubuntu                -> \EFI\ubuntu\...      (dir absent = dead)
#   Boot0008  Garuda                -> \EFI\Garuda\...      (dir absent = dead)
#
# Keeps:
#   Boot0009* "UEFI: ...TOSHIBA..." -> \EFI\Boot\BootX64.efi  (working fallback;
#             kept as a SECONDARY boot option until a reboot proves the new entry)
#   Boot000A-000D  firmware-generated generic entries (Floppy/USB/CD/NIC)
#
# Only NVRAM variables are changed. No file on /dev/nvme0n1p1 is touched.
#
# USAGE (run yourself; needs interactive sudo):
#     sudo bash ~/clean-efi-entries.sh
# =============================================================================
set -uo pipefail

DISK="/dev/nvme0n1"
PART="1"
ESP="/boot/EFI"
LOADER='\EFI\Boot\BootX64.efi'         # the actual systemd-boot fallback binary
LABEL="Arch Linux"
BACKUP_DIR="/root/efi-backups"

# Dead entries to delete, with the label each MUST currently have (guard against
# firmware renumbering: we never delete a number whose label doesn't match).
DEAD_NUMS=(0000 0001 0008)
declare -A DEAD_LABEL=( [0000]="Windows Boot Manager" [0001]="ubuntu" [0008]="Garuda" )
# Their corresponding ESP dirs that must be ABSENT to confirm they're dead.
DEAD_DIRS=("$ESP/Microsoft" "$ESP/ubuntu" "$ESP/Garuda")

KEEP_FALLBACK="0009"
FIRMWARE_ENTRIES="000A,000B,000C,000D"

c_b=$'\033[1;34m'; c_g=$'\033[1;32m'; c_y=$'\033[1;33m'; c_r=$'\033[1;31m'; c_0=$'\033[0m'
info() { printf '%s==>%s %s\n'  "$c_b" "$c_0" "$*"; }
ok()   { printf '%s ok %s %s\n' "$c_g" "$c_0" "$*"; }
warn() { printf '%swarn%s %s\n' "$c_y" "$c_0" "$*" >&2; }
err()  { printf '%serr %s %s\n' "$c_r" "$c_0" "$*" >&2; }

[ "$(id -u)" -eq 0 ] || { err "Run with sudo: sudo bash $0"; exit 1; }
command -v efibootmgr >/dev/null || { err "efibootmgr not found (pacman -S efibootmgr)"; exit 1; }

# Return the label of boot entry $1 (text between "BootXXXX*/space" and the tab).
entry_label() {
  efibootmgr | awk -F'\t' -v n="$1" '
    $0 ~ ("^Boot" n) {
      h=$1; sub(/^Boot[0-9A-Fa-f]{4}/,"",h); sub(/^\*?[[:space:]]+/,"",h); print h; exit
    }'
}
# Return the 4-hex number of the (first) entry whose label == $1, else empty.
num_for_label() {
  efibootmgr | awk -F'\t' -v want="$1" '
    /^Boot[0-9A-Fa-f]{4}/ {
      num=substr($1,5,4); h=$1
      sub(/^Boot[0-9A-Fa-f]{4}/,"",h); sub(/^\*?[[:space:]]+/,"",h)
      if (h==want) { print num; exit }
    }'
}

# =============================================================================
# PHASE 1 — verify everything BEFORE any destructive change
# =============================================================================
info "Verifying it's safe to proceed (no changes yet)..."

# 1a. Dead-bootloader dirs must be absent (the whole premise of "dead pointers").
for d in "${DEAD_DIRS[@]}"; do
  if [ -e "$d" ]; then
    err "STOP: $d EXISTS — that bootloader's files are still on the ESP."
    err "These entries may NOT be dead. Assess before deleting NVRAM entries. Aborting (nothing changed)."
    exit 1
  fi
done
ok "ESP has no Microsoft/ubuntu/Garuda dirs (entries are dead pointers)."

# 1b. The working fallback we intend to keep must exist, and its loader file too.
[ -n "$(entry_label "$KEEP_FALLBACK")" ] || { err "STOP: Boot$KEEP_FALLBACK (fallback) not found. Aborting."; exit 1; }
if [ ! -f "$ESP/Boot/BootX64.efi" ] && [ ! -f "$ESP/BOOT/BOOTX64.EFI" ]; then
  err "STOP: loader file for '$LOADER' not found on ESP. Aborting (won't create an entry to a missing file)."
  exit 1
fi
ok "Fallback Boot$KEEP_FALLBACK present and its loader file exists on the ESP."

# 1c. Each dead number must currently carry its expected label.
for n in "${DEAD_NUMS[@]}"; do
  got="$(entry_label "$n")"
  if [ -z "$got" ]; then
    warn "Boot$n not present (already removed?) — will skip it."
  elif [ "$got" != "${DEAD_LABEL[$n]}" ]; then
    err "STOP: Boot$n is labeled '$got', expected '${DEAD_LABEL[$n]}'."
    err "Boot numbering may have changed. Refusing to delete the wrong entry. Aborting (nothing changed)."
    exit 1
  else
    ok "Boot$n verified = '${DEAD_LABEL[$n]}'"
  fi
done

# Guard against creating a duplicate if an "Arch Linux" entry already exists.
EXISTING_ARCH="$(num_for_label "$LABEL")"

# =============================================================================
# PHASE 2 — backup, then make changes
# =============================================================================
mkdir -p "$BACKUP_DIR"
BEFORE="$BACKUP_DIR/efibootmgr-before-$(date +%s).txt"
efibootmgr -v > "$BEFORE" || { err "could not write backup $BEFORE — aborting before any change."; exit 1; }
ok "Backed up current NVRAM state -> $BEFORE"

# 2a. Delete the dead entries (only those that verified above).
for n in "${DEAD_NUMS[@]}"; do
  got="$(entry_label "$n")"
  [ -n "$got" ] || continue   # already gone
  info "Deleting Boot$n ('$got')"
  efibootmgr -b "$n" -B >/dev/null && ok "deleted Boot$n" || warn "failed to delete Boot$n (continuing)"
done

# 2b. Create the named Arch entry (skip if one already exists).
if [ -n "$EXISTING_ARCH" ]; then
  warn "An '$LABEL' entry already exists (Boot$EXISTING_ARCH) — not creating a duplicate."
  NEW="$EXISTING_ARCH"
else
  info "Creating '$LABEL' entry -> disk $DISK part $PART loader $LOADER"
  efibootmgr --create --disk "$DISK" --part "$PART" --label "$LABEL" --loader "$LOADER" >/dev/null \
    || { err "efibootmgr --create failed. Dead entries were removed; fallback Boot$KEEP_FALLBACK still boots."; err "Backup: $BEFORE"; exit 1; }
  NEW="$(num_for_label "$LABEL")"
fi

if [ -z "$NEW" ]; then
  err "Could not determine the new entry's number from efibootmgr output."
  err "NOT touching BootOrder. Set it yourself once you see the number:"
  err "    efibootmgr            # find the 'Arch Linux' BootXXXX"
  err "    efibootmgr -o XXXX,$KEEP_FALLBACK,$FIRMWARE_ENTRIES"
  efibootmgr -v > "$BACKUP_DIR/efibootmgr-after-$(date +%s).txt" 2>/dev/null
  exit 1
fi
ok "New entry is Boot$NEW ('$LABEL')"

# 2c. Set boot order: new Arch first, working fallback second, firmware last.
NEW_ORDER="$NEW,$KEEP_FALLBACK,$FIRMWARE_ENTRIES"
info "Setting BootOrder -> $NEW_ORDER"
efibootmgr -o "$NEW_ORDER" >/dev/null && ok "BootOrder set" || warn "failed to set BootOrder — set manually: efibootmgr -o $NEW_ORDER"

# 2d. After-state snapshot.
AFTER="$BACKUP_DIR/efibootmgr-after-$(date +%s).txt"
efibootmgr -v > "$AFTER" 2>/dev/null && ok "Saved after-state -> $AFTER"

# =============================================================================
# PHASE 3 — report + recovery note
# =============================================================================
echo
ok "=============================  DONE  ============================="
echo "Current boot entries / order:"
echo
efibootmgr
echo
echo "What changed (NVRAM only — no files on the ESP were touched):"
echo "  - deleted dead entries: Boot0000 (Windows), Boot0001 (ubuntu), Boot0008 (Garuda)"
echo "  + created Boot$NEW '$LABEL' -> $LOADER"
echo "  * BootOrder = $NEW_ORDER  (Arch first; fallback Boot$KEEP_FALLBACK kept second)"
echo "  = untouched: Boot$KEEP_FALLBACK fallback, firmware entries $FIRMWARE_ENTRIES"
echo
echo "Backups:"
echo "  before: $BEFORE"
echo "  after:  $AFTER"
echo
echo "RECOVERY if the new entry misbehaves after reboot:"
echo "  * Nothing on the ESP changed, and Boot$KEEP_FALLBACK still points at the same"
echo "    working \\EFI\\Boot\\BootX64.efi — so the machine still boots Arch via the"
echo "    fallback even if Boot$NEW is wrong. In firmware you can also pick the USB"
echo "    entry to boot install media."
echo "  * To restore the previous BootOrder exactly, read the 'BootOrder:' line in"
echo "    $BEFORE and run:  efibootmgr -o <that comma list>"
echo "  * The deleted entries were dead pointers; recreating them isn't needed. If you"
echo "    ever want to, $BEFORE has each one's full device path (efibootmgr -v dump)."
echo
echo "NEXT: reboot and confirm it boots into Arch via '$LABEL' (Boot$NEW). Then come"
echo "back and we'll decide whether to also remove the Boot$KEEP_FALLBACK fallback."
