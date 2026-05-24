#!/usr/bin/env bash
# Regenerate the tracked package lists from the current system.
# Re-run this after installing/removing packages, then commit the result:
#   bash packages/refresh-package-lists.sh && git commit -am "Update package lists"
set -euo pipefail

# Resolve the directory this script lives in, so it works from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Official-repo packages, explicitly installed (not pulled in as dependencies).
pacman -Qqen > "$SCRIPT_DIR/pacman-explicit.txt"
# Foreign packages (AUR / manually built), explicitly installed.
pacman -Qqem > "$SCRIPT_DIR/pacman-foreign.txt"

echo "Updated:"
echo "  pacman-explicit.txt  ($(wc -l < "$SCRIPT_DIR/pacman-explicit.txt") packages)"
echo "  pacman-foreign.txt   ($(wc -l < "$SCRIPT_DIR/pacman-foreign.txt") packages)"
