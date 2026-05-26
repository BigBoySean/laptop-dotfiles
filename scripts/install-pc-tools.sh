#!/usr/bin/env bash
# =============================================================================
# install-pc-tools.sh
#
# Install the pc-* helper scripts (pc-remote, pc-home, pc-connect) from this
# repo into /usr/local/bin/ as root-owned 0755 executables.
#
# These are not user-config files — they live in /usr/local/bin/ because they
# need to be on $PATH for hyprland binds, qml execDetached calls, etc., and
# they're independent of any one user's home dir. They're separated from
# install.sh (the user-config installer) for the same reason as wifi-fix.sh
# and friends: install.sh deliberately doesn't touch root-level state.
#
# What each script does:
#   pc-remote   `ssh pc remote-mode`           switch desktop PC to single-monitor
#   pc-home     `ssh pc home-mode`             restore desktop PC monitors
#   pc-connect  remote-mode -> moonlight stream -> home-mode (with Hyprland
#               keyboard-passthrough submap toggled around the stream)
#
# Idempotent: re-running just rewrites the files. Pre-existing /usr/local/bin/
# files with the same name will be overwritten (no backup — these scripts are
# tracked in the repo).
#
# USAGE (run yourself; needs interactive sudo):
#     sudo bash ~/dotfiles/scripts/install-pc-tools.sh
# =============================================================================
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "error: must run as root (use sudo)" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/local-bin"

c_b=$'\033[1;34m'; c_g=$'\033[1;32m'; c_r=$'\033[1;31m'; c_0=$'\033[0m'
info() { printf '%s==>%s %s\n'  "$c_b" "$c_0" "$*"; }
ok()   { printf '%s ok %s %s\n' "$c_g" "$c_0" "$*"; }
die()  { printf '%serror%s %s\n' "$c_r" "$c_0" "$*" >&2; exit 1; }

[ -d "$SRC_DIR" ] || die "missing source dir: $SRC_DIR"

for name in pc-remote pc-home pc-connect; do
    src="$SRC_DIR/$name"
    dest="/usr/local/bin/$name"
    [ -f "$src" ] || die "missing source: $src"
    info "installing $dest"
    install -m 0755 -o root -g root "$src" "$dest"
    ok "$dest"
done

echo
info "installed pc-* scripts:"
ls -l /usr/local/bin/pc-remote /usr/local/bin/pc-home /usr/local/bin/pc-connect
