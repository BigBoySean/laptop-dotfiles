#!/usr/bin/env bash
#
# setup-pretty-boot.sh  --  Plymouth splash + hidden bootloader menu for this Arch laptop
#
# Bootloader detected: systemd-boot.  GPU: Intel i915 (KMS hook present).
# This script is IDEMPOTENT and backs up every file it changes with a timestamped .bak.
#
# Run with:   sudo bash ~/setup-pretty-boot.sh
# Do NOT reboot from inside this script. Reboot yourself when ready.
#
# RECOVERY (after this is applied): the bootloader menu is hidden (timeout 0).
#   Hold SPACE during boot to reveal the menu, then pick
#   "Arch Linux (Safe / Verbose Boot)".  At the menu you can also press 'e'
#   to live-edit a kernel cmdline (e.g. remove 'splash') without saving.

set -uo pipefail

# ---------------------------------------------------------------------------
# Config (verified during read-only investigation on 2026-05-24)
# ---------------------------------------------------------------------------
THEME="arch-charge-big"
AUR_PKG="plymouth-theme-arch-charge-big"
MKINIT="/etc/mkinitcpio.conf"
LOADER="/boot/loader/loader.conf"
ENTRIES_DIR="/boot/loader/entries"
DEFAULT_ENTRY="2026-05-23_15-15-17_linux.conf"   # the primary (non-fallback) entry
SAFE_ENTRY="arch-safe.conf"
PRIMARY_IMG="/boot/initramfs-linux.img"

TS="$(date +%Y%m%d-%H%M%S)"
CHANGED=()        # list of "file -> backup" lines for the final report
HOOKS_CHANGED=0

die()  { echo "ERROR: $*" >&2; echo "Aborting. No further changes made." >&2; exit 1; }
note() { echo "  -> $*"; }
backup() {
    # backup <file>  : timestamped copy, recorded for the report
    local f="$1" b
    b="${f}.bak.${TS}"
    cp -a -- "$f" "$b" || die "could not back up $f"
    CHANGED+=("$f    (backup: $b)")
    note "backed up $f -> $b"
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "must be run as root:  sudo bash ~/setup-pretty-boot.sh"

# Sanity: confirm we really are on systemd-boot with the expected entry.
[ -f "$LOADER" ]                      || die "$LOADER not found (is this systemd-boot?)"
[ -d "$ENTRIES_DIR" ]                 || die "$ENTRIES_DIR not found"
[ -f "$ENTRIES_DIR/$DEFAULT_ENTRY" ]  || die "default entry $ENTRIES_DIR/$DEFAULT_ENTRY not found"
[ -f "$MKINIT" ]                      || die "$MKINIT not found"

# Determine the unprivileged user for the AUR build (makepkg refuses root).
AURUSER="${SUDO_USER:-}"
[ -z "$AURUSER" ] && AURUSER="$(logname 2>/dev/null || true)"
[ -z "$AURUSER" ] || [ "$AURUSER" = "root" ] && \
    die "cannot determine a non-root user for the AUR build. Run via 'sudo bash', not a root shell."
command -v paru >/dev/null 2>&1 || die "paru not found (needed to build the AUR theme '$AUR_PKG')"

echo "=============================================================="
echo " setup-pretty-boot.sh   (timestamp $TS)"
echo " theme=$THEME   user-for-AUR=$AURUSER"
echo "=============================================================="

# ---------------------------------------------------------------------------
# A. Install plymouth (official) + theme (AUR, built as the normal user)
# ---------------------------------------------------------------------------
echo
echo "[A] Installing plymouth + theme ..."
pacman -S --needed --noconfirm plymouth || die "pacman failed to install plymouth"

# AUR package: build & install as $AURUSER (paru will sudo to install; you may be
# prompted once for your password here -- that is expected).
if pacman -Qq "$AUR_PKG" >/dev/null 2>&1; then
    note "$AUR_PKG already installed"
else
    note "building $AUR_PKG via paru as $AURUSER (may prompt for sudo password)"
    sudo -u "$AURUSER" -H paru -S --needed --noconfirm "$AUR_PKG" \
        || die "paru failed to install $AUR_PKG"
fi

# Confirm the theme is actually available before we touch the initramfs.
# (Disk check, not a piped `plymouth-set-default-theme -l | grep`: that pipeline
#  trips SIGPIPE under `set -o pipefail` because grep -q closes the pipe early.)
if [ -f "/usr/share/plymouth/themes/$THEME/$THEME.plymouth" ]; then
    note "theme '$THEME' is available (disk-verified)"
else
    die "theme '$THEME' not found on disk at /usr/share/plymouth/themes/$THEME/$THEME.plymouth"
fi

# ---------------------------------------------------------------------------
# B. Add 'plymouth' to mkinitcpio HOOKS (after udev/systemd, before autodetect)
# ---------------------------------------------------------------------------
echo
echo "[B] Ensuring 'plymouth' is in HOOKS ..."
if grep -qE '^HOOKS=\(.*\bplymouth\b.*\)' "$MKINIT"; then
    note "plymouth already present in HOOKS -- leaving as-is"
else
    backup "$MKINIT"
    if grep -qE '^HOOKS=\(.*\bsystemd\b' "$MKINIT"; then
        sed -i -E '/^HOOKS=\(/ s/\bsystemd\b/systemd plymouth/' "$MKINIT" \
            || die "failed to edit HOOKS (systemd)"
    elif grep -qE '^HOOKS=\(.*\budev\b' "$MKINIT"; then
        sed -i -E '/^HOOKS=\(/ s/\budev\b/udev plymouth/' "$MKINIT" \
            || die "failed to edit HOOKS (udev)"
    else
        die "neither 'udev' nor 'systemd' found in HOOKS; not editing blindly"
    fi
    grep -qE '^HOOKS=\(.*\bplymouth\b' "$MKINIT" || die "HOOKS edit did not take"
    HOOKS_CHANGED=1
    note "new HOOKS: $(grep -E '^HOOKS=' "$MKINIT")"
fi

# ---------------------------------------------------------------------------
# C. Set default theme and rebuild initramfs (-R does the mkinitcpio rebuild)
# ---------------------------------------------------------------------------
echo
echo "[C] Setting theme + rebuilding initramfs ..."
CURRENT_THEME="$(plymouth-set-default-theme 2>/dev/null || true)"
if [ "$CURRENT_THEME" = "$THEME" ] && [ "$HOOKS_CHANGED" -eq 0 ]; then
    note "theme already '$THEME' and HOOKS unchanged -- skipping rebuild"
else
    plymouth-set-default-theme -R "$THEME" || die "plymouth-set-default-theme -R failed"
fi

# Verify the rebuilt initramfs actually contains plymouth BEFORE touching the
# bootloader. If this fails we stop here, leaving the bootloader untouched so
# the machine still boots exactly as before.
if command -v lsinitcpio >/dev/null 2>&1; then
    lsinitcpio "$PRIMARY_IMG" 2>/dev/null | grep -qi 'plymouth' \
        || die "initramfs $PRIMARY_IMG does not contain plymouth after rebuild"
    note "verified: $PRIMARY_IMG contains plymouth"
fi

# ---------------------------------------------------------------------------
# D. systemd-boot: safe entry, quiet splash on default, timeout 0 + default
# ---------------------------------------------------------------------------
echo
echo "[D] Configuring systemd-boot ..."

# D0. Capture pristine kernel options from the default entry (strip any
#     quiet/splash so the safe entry is fully verbose even on a re-run).
PRISTINE_OPTS="$(grep -E '^options ' "$ENTRIES_DIR/$DEFAULT_ENTRY" | head -n1 | sed -E 's/^options[[:space:]]+//')"
[ -n "$PRISTINE_OPTS" ] || die "could not read options from $DEFAULT_ENTRY"
SAFE_OPTS="$(echo "$PRISTINE_OPTS" | sed -E 's/(^| )(quiet|splash)( |$)/ /g; s/  +/ /g; s/^ //; s/ $//')"

# Mirror linux/initrd lines from the default entry for the safe entry.
SAFE_LINUX="$(grep -E '^linux '  "$ENTRIES_DIR/$DEFAULT_ENTRY" | head -n1 | sed -E 's/^linux[[:space:]]+//')"
SAFE_INITRD="$(grep -E '^initrd ' "$ENTRIES_DIR/$DEFAULT_ENTRY" | head -n1 | sed -E 's/^initrd[[:space:]]+//')"
[ -n "$SAFE_LINUX" ] && [ -n "$SAFE_INITRD" ] || die "could not read linux/initrd from $DEFAULT_ENTRY"

# D1. Create/refresh the Safe / Verbose entry (no quiet splash).
SAFE_PATH="$ENTRIES_DIR/$SAFE_ENTRY"
TMP_SAFE="$(mktemp)"
cat > "$TMP_SAFE" <<EOF
# Created by setup-pretty-boot.sh -- verbose recovery entry (no quiet/splash)
title   Arch Linux (Safe / Verbose Boot)
linux   $SAFE_LINUX
initrd  $SAFE_INITRD
options $SAFE_OPTS
EOF
if [ -f "$SAFE_PATH" ] && cmp -s "$TMP_SAFE" "$SAFE_PATH"; then
    note "safe entry $SAFE_ENTRY already up-to-date"
    rm -f "$TMP_SAFE"
else
    [ -f "$SAFE_PATH" ] && backup "$SAFE_PATH"
    install -m 0644 "$TMP_SAFE" "$SAFE_PATH" || die "could not write $SAFE_PATH"
    rm -f "$TMP_SAFE"
    CHANGED+=("$SAFE_PATH    (created/updated)")
    note "wrote safe entry: $SAFE_PATH  (options: $SAFE_OPTS)"
fi

# D2. Add 'quiet splash' to the default entry's options line.
DEF_PATH="$ENTRIES_DIR/$DEFAULT_ENTRY"
if grep -E '^options ' "$DEF_PATH" | grep -qw quiet && \
   grep -E '^options ' "$DEF_PATH" | grep -qw splash; then
    note "default entry already has 'quiet splash'"
else
    backup "$DEF_PATH"
    TMP_DEF="$(mktemp)"
    awk '
        /^options / {
            if ($0 !~ /(^| )quiet( |$)/)  $0 = $0 " quiet"
            if ($0 !~ /(^| )splash( |$)/) $0 = $0 " splash"
        }
        { print }
    ' "$DEF_PATH" > "$TMP_DEF" || die "awk failed on $DEF_PATH"
    install -m 0644 "$TMP_DEF" "$DEF_PATH" || die "could not write $DEF_PATH"
    rm -f "$TMP_DEF"
    note "default entry now: $(grep -E '^options ' "$DEF_PATH")"
fi

# D3. loader.conf -> timeout 0 + explicit default (deterministic with hidden menu).
LOADER_NEEDS_BACKUP=0
grep -qE '^timeout 0$'                       "$LOADER" || LOADER_NEEDS_BACKUP=1
grep -qE "^default ${DEFAULT_ENTRY//./\\.}$" "$LOADER" || LOADER_NEEDS_BACKUP=1
if [ "$LOADER_NEEDS_BACKUP" -eq 1 ]; then
    backup "$LOADER"
    # timeout 0
    if grep -qE '^timeout[[:space:]]' "$LOADER"; then
        sed -i -E 's/^timeout[[:space:]].*/timeout 0/' "$LOADER"
    elif grep -qE '^#timeout[[:space:]]' "$LOADER"; then
        sed -i -E 's/^#timeout[[:space:]].*/timeout 0/' "$LOADER"
    else
        printf 'timeout 0\n' >> "$LOADER"
    fi
    # explicit default
    if grep -qE '^default[[:space:]]' "$LOADER"; then
        sed -i -E "s|^default[[:space:]].*|default $DEFAULT_ENTRY|" "$LOADER"
    elif grep -qE '^#default[[:space:]]' "$LOADER"; then
        sed -i -E "s|^#default[[:space:]].*|default $DEFAULT_ENTRY|" "$LOADER"
    else
        printf 'default %s\n' "$DEFAULT_ENTRY" >> "$LOADER"
    fi
    note "loader.conf now: $(grep -E '^(timeout|default)' "$LOADER" | tr '\n' ' ')"
else
    note "loader.conf already has 'timeout 0' and correct default"
fi

# ---------------------------------------------------------------------------
# E. Report
# ---------------------------------------------------------------------------
echo
echo "=============================================================="
echo " DONE -- nothing was rebooted or restarted."
echo "=============================================================="
echo
echo "Files changed this run (with backups):"
if [ "${#CHANGED[@]}" -eq 0 ]; then
    echo "  (none -- everything was already in the desired state)"
else
    for c in "${CHANGED[@]}"; do echo "  - $c"; done
fi
echo
echo "Current state:"
echo "  HOOKS:        $(grep -E '^HOOKS='  "$MKINIT")"
echo "  theme:        $(plymouth-set-default-theme 2>/dev/null)"
echo "  loader.conf:  $(grep -E '^(timeout|default)' "$LOADER" | tr '\n' '  ')"
echo "  default entry options: $(grep -E '^options ' "$ENTRIES_DIR/$DEFAULT_ENTRY")"
echo "  safe entry options:    $(grep -E '^options ' "$SAFE_PATH")"
echo
echo "RECOVERY: the bootloader menu is hidden (timeout 0)."
echo "  If boot breaks: hold SPACE during boot to reveal the menu, then pick"
echo "  \"Arch Linux (Safe / Verbose Boot)\" (verbose, no quiet/splash)."
echo "  Deeper fallback: also pick \"Arch Linux (linux-fallback)\", or press 'e'"
echo "  at the menu to remove 'splash' from a cmdline for one boot."
echo
echo "Reboot when YOU are ready (this script will not do it)."
