#!/usr/bin/env fish
# Regenerate kitty's colour theme from Caelestia's active scheme.
# Mirrors how foot/other terminals follow ~/.local/state/caelestia/scheme.json.
# New kitty windows pick up the result via `include current-theme.conf`;
# already-open kitty windows running fish also update live via Caelestia's
# OSC colour sequences (sourced in fish config), so a watcher push isn't needed.
set -l scheme $HOME/.local/state/caelestia/scheme.json
set -l out $HOME/.config/kitty/current-theme.conf
test -f $scheme; or exit 0
jq -r '.colours as $c | ([
  "foreground #\($c.text)",
  "background #\($c.background)",
  "cursor #\($c.secondary)",
  "cursor_text_color #\($c.background)",
  "selection_foreground #\($c.background)",
  "selection_background #\($c.secondary)"
] + [range(0;16) | "color\(.) #\($c["term" + (.|tostring)])"]) | .[]' $scheme >$out.tmp
and mv $out.tmp $out
