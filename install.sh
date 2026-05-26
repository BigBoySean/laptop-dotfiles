#!/usr/bin/env bash
# =============================================================================
# install.sh — rebuild this Arch + Hyprland + Caelestia setup on a fresh laptop.
#
# Assumes you have ALREADY:
#   - installed Arch base with working networking
#   - installed `paru` (AUR helper)
#   - a regular user account with sudo (you are running this AS that user)
#
# This script installs packages and lays down user configs. It does NOT touch
# root-level system state (bootloader, PAM, networkd, SDDM, power tuning) — those
# are separate, reviewed, destructive scripts you run by hand afterwards. See the
# "ROOT STEPS REMAINING" section it prints at the end.
#
# Safe to re-run: package installs use --needed, config copies are idempotent,
# and the first run backs up any pre-existing config once (to *.pre-dotfiles.bak).
# =============================================================================
set -euo pipefail

# Resolve the repo root (this script's directory) so it works from anywhere.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# --- pretty output ----------------------------------------------------------
c_blue=$'\033[1;34m'; c_green=$'\033[1;32m'; c_yellow=$'\033[1;33m'; c_red=$'\033[1;31m'; c_reset=$'\033[0m'
info()  { printf '%s==>%s %s\n'  "$c_blue"   "$c_reset" "$*"; }
ok()    { printf '%s  ok%s %s\n' "$c_green"  "$c_reset" "$*"; }
warn()  { printf '%swarn%s %s\n' "$c_yellow" "$c_reset" "$*" >&2; }
die()   { printf '%serror%s %s\n' "$c_red"   "$c_reset" "$*" >&2; exit 1; }

# --- 1. preflight: required tools -------------------------------------------
info "Checking prerequisites (pacman, paru, sudo)..."
command -v pacman >/dev/null || die "pacman not found — are you on Arch?"
command -v sudo   >/dev/null || die "sudo not found — install it and add your user to a sudo group."
command -v paru   >/dev/null || die "paru not found — install it first:
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si"
# Confirm sudo actually works (will prompt for password if needed).
sudo -v || die "sudo authentication failed."
ok "pacman, paru, sudo all present."

EXPLICIT="$REPO_DIR/packages/pacman-explicit.txt"
FOREIGN="$REPO_DIR/packages/pacman-foreign.txt"
[ -f "$EXPLICIT" ] || die "missing $EXPLICIT"
[ -f "$FOREIGN" ]  || die "missing $FOREIGN"

# --- 2. show plan, confirm --------------------------------------------------
cat <<PLAN

${c_blue}This will:${c_reset}
  1. Install $(wc -l < "$EXPLICIT") official packages   (sudo pacman -S --needed)
  2. Install $(wc -l < "$FOREIGN") AUR/foreign packages  (paru -S --needed)
  3. Copy user configs into ${CONFIG_HOME}:
       hypr/hyprland.conf, caelestia/, quickshell/caelestia (override layer),
       kitty/, fuzzel/, foot/, systemd user units
       (any existing file is backed up once to *.pre-dotfiles.bak)
  4. Enable user services: caelestia-kitty-theme.path, ydotool.service

It will NOT run the root-level scripts (bootloader/PAM/network/SDDM/power) —
those are listed at the end for you to run manually.

PLAN
read -rp "Proceed? [y/N] " reply
case "$reply" in
  [yY]|[yY][eE][sS]) ;;
  *) die "Aborted by user. Nothing was changed." ;;
esac

# --- 3. official packages ---------------------------------------------------
info "Installing official packages..."
sudo pacman -S --needed --noconfirm - < "$EXPLICIT"
ok "official packages installed."

# --- 4. AUR / foreign packages ----------------------------------------------
info "Installing AUR/foreign packages..."
paru -S --needed --noconfirm - < "$FOREIGN"
ok "AUR/foreign packages installed."

# --- 5. user configs --------------------------------------------------------
# Back up a destination file once (only if it exists and no backup exists yet).
backup_once() {
  local dest="$1"
  if [ -e "$dest" ] && [ ! -e "$dest.pre-dotfiles.bak" ]; then
    cp -a "$dest" "$dest.pre-dotfiles.bak"
    warn "backed up existing $dest -> $dest.pre-dotfiles.bak"
  fi
}

info "Installing user configs into $CONFIG_HOME ..."

# hypr: only the personal entrypoint (NOT the symlinks to upstream Caelestia).
backup_once "$CONFIG_HOME/hypr/hyprland.conf"
install -Dm644 "$REPO_DIR/config/hypr/hyprland.conf" "$CONFIG_HOME/hypr/hyprland.conf"
ok "hypr/hyprland.conf"

# caelestia: copy in, preserve modes, never delete anything already there.
mkdir -p "$CONFIG_HOME/caelestia"
rsync -a "$REPO_DIR/config/caelestia/" "$CONFIG_HOME/caelestia/"
ok "caelestia/ (rsync, no --delete)"

# quickshell: caelestia override layer.
#   Quickshell picks the first XDG config dir containing
#   <dir>/quickshell/caelestia/shell.qml as the whole config root — it does NOT
#   merge file-by-file. So to override a single file (OsIcon.qml is the PC-connect
#   button override), mirror the system tree as a directory of symlinks into
#   ~/.config, then drop our real files on top of the symlinks they'd otherwise be.
#   Re-running picks up any new upstream files (cp -rsn skips existing entries).
if [ -d "/etc/xdg/quickshell/caelestia" ] && [ -d "$REPO_DIR/config/quickshell/caelestia" ]; then
  mkdir -p "$CONFIG_HOME/quickshell/caelestia"
  cp -rsn /etc/xdg/quickshell/caelestia/. "$CONFIG_HOME/quickshell/caelestia/"
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO_DIR/config/quickshell/"}"
    dest="$CONFIG_HOME/quickshell/$rel"
    backup_once "$dest"
    rm -f "$dest"   # drop the symlink so install writes a real file, not into /etc/xdg
    install -Dm644 "$src" "$dest"
  done < <(find "$REPO_DIR/config/quickshell" -type f -print0)
  ok "quickshell/caelestia/ (symlink mirror + real overrides)"
else
  warn "skipping quickshell override (need /etc/xdg/quickshell/caelestia and repo's config/quickshell/caelestia)"
fi

# kitty
for f in "$REPO_DIR"/config/kitty/*; do
  [ -e "$f" ] || continue
  install -Dm644 "$f" "$CONFIG_HOME/kitty/$(basename "$f")"
done
ok "kitty/"

# fuzzel (keep restrictive perms)
if [ -f "$REPO_DIR/config/fuzzel/fuzzel.ini" ]; then
  install -Dm600 "$REPO_DIR/config/fuzzel/fuzzel.ini" "$CONFIG_HOME/fuzzel/fuzzel.ini"
  ok "fuzzel/fuzzel.ini"
fi

# foot (only if we shipped one)
if compgen -G "$REPO_DIR/config/foot/*" >/dev/null; then
  for f in "$REPO_DIR"/config/foot/*; do
    install -Dm644 "$f" "$CONFIG_HOME/foot/$(basename "$f")"
  done
  ok "foot/"
fi

# systemd user units
if compgen -G "$REPO_DIR/config/systemd-user/*" >/dev/null; then
  for f in "$REPO_DIR"/config/systemd-user/*; do
    install -Dm644 "$f" "$CONFIG_HOME/systemd/user/$(basename "$f")"
  done
  ok "systemd user units copied"
  systemctl --user daemon-reload || warn "daemon-reload failed (no user session yet? safe to ignore until next login)"
  # Enable the units that should run. caelestia-kitty-theme.path ships in this
  # repo; ydotool.service is provided by the ydotool package installed above.
  for unit in caelestia-kitty-theme.path ydotool.service; do
    if systemctl --user enable "$unit" 2>/dev/null; then
      ok "enabled $unit"
    else
      warn "could not enable $unit now — run 'systemctl --user enable $unit' after first login"
    fi
  done
fi

ok "All user configs installed."

# --- 6. root steps remaining ------------------------------------------------
cat <<ROOT

${c_yellow}=====================  ROOT STEPS REMAINING  =====================${c_reset}
These need sudo with a real password prompt and several are destructive
(bootloader, PAM, network config). Run them YOURSELF, in this order, from
${REPO_DIR}:

    sudo bash scripts/wifi-fix.sh
    sudo bash scripts/fix-networkd-wlan0.sh
    sudo bash scripts/post-install-root.sh
    sudo bash scripts/set-sddm-astronaut.sh
    sudo bash scripts/setup-pretty-boot.sh
    sudo bash scripts/tune-power.sh

${c_yellow}=================================================================${c_reset}

${c_green}After the root scripts, reboot.${c_reset} Then log in, open kitty (Super+Enter),
and run  ${c_blue}caelestia shell -d${c_reset}  if the shell didn't come up on its own.
ROOT
