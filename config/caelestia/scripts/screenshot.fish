#!/usr/bin/env fish
# Screenshot helper: saves to ~/Pictures/Screenshots AND copies to clipboard.
# Usage: screenshot.fish region   # user-selected area (grim + slurp)
#        screenshot.fish full     # whole output
set -l mode $argv[1]
set -l dir $HOME/Pictures/Screenshots
mkdir -p $dir
set -l file $dir/(date +%Y-%m-%d_%H-%M-%S).png

switch $mode
    case region
        set -l geom (slurp) ; or exit 1   # exit cleanly if selection cancelled
        grim -g "$geom" $file
    case full '*'
        grim $file
end

wl-copy < $file
notify-send -i $file "Screenshot saved" (basename $file) -a Shell 2>/dev/null
