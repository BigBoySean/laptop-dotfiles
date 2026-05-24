#!/usr/bin/env fish
# move-or-send.fish — move (swap) the active window in a direction, but if it's
# already at the layout edge horizontally, send it to the adjacent workspace.
#
#   l / r : try `swapwindow`; if the window's position didn't change (it was at
#           the edge) fall through to `movetoworkspace -1` / `+1`.
#   u / d : plain `swapwindow` — workspace escape only makes sense horizontally.

set dir $argv[1]

switch $dir
    case u d
        hyprctl dispatch swapwindow $dir
        exit 0
    case l r
        # noop — handled below
    case '*'
        echo "usage: move-or-send.fish {l|r|u|d}" >&2
        exit 1
end

# Capture position before the swap. Bail cleanly if there's no active window.
set before (hyprctl activewindow -j | jq -r '.at | @csv')
if test -z "$before" -o "$before" = "null"
    exit 0
end

hyprctl dispatch swapwindow $dir

# If the position is unchanged the window was at the edge — send it to the
# adjacent workspace instead.
set after (hyprctl activewindow -j | jq -r '.at | @csv')
if test "$after" = "$before"
    switch $dir
        case r
            hyprctl dispatch movetoworkspace +1
        case l
            hyprctl dispatch movetoworkspace -1
    end
end
