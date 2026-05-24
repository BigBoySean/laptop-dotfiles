# Setup Snapshot

_Generated 2026-05-23 from `~/.config`. Arch Linux · Hyprland (Wayland) · Caelestia (Quickshell) shell · laptop (single internal display `eDP-1`)._

> ⚠️ **Read the "Potentially broken" section first.** The Hyprland config that is *actually loaded* is a generated stub — almost none of the rich Caelestia keybinds/rules/styling below are active right now.

---

## TL;DR

- The machine boots Hyprland via **uwsm**, which launches `~/.config/hypr/hyprland.conf`.
- That file is **Hyprland's auto-generated fallback stub** — it only runs `caelestia shell` plus 6 basic keybinds.
- The full Caelestia Hyprland config (keybinds, window rules, blur/shadow/gaps, autostart, input tuning) is present and symlinked in, but **nothing sources it**, so it's dormant.
- The Caelestia **shell daemon itself does run** (bar, notifications, OSD, lock, idle, battery, launcher backend) — but its keyboard triggers live in the dormant keybind file, so most of them don't fire.

---

## What's installed

**Compositor / Wayland stack**
`hyprland`, `xdg-desktop-portal-hyprland`, `uwsm` (session launcher), `hyprpicker`, `hyprcursor`, `hyprgraphics`, `hyprlang`, `hyprutils`, `hyprtoolkit`, `hyprwire`, `hyprwayland-scanner`, `hyprland-guiutils`

**Desktop shell**
`caelestia-meta` (r183), `caelestia-shell` (1.6.2), `caelestia-cli` (1.0.8), `quickshell-git`, `app2unit` (launches apps into systemd slices). Shell QML lives at `/etc/xdg/quickshell/caelestia` (modules: bar, dashboard, launcher, controlcenter, sidebar, notifications, osd, lock, session, utilities, windowinfo).

**Terminals** — `foot` (Caelestia's choice, themed) and `kitty` (the stub's choice, **unconfigured**)
**Launchers** — `fuzzel` (used by Caelestia for clipboard/emoji), `wofi` (installed but unused)
**Clipboard / screenshot** — `cliphist`, `wl-clipboard`, `grim`, `slurp`, `hyprpicker`
**CLI tools** — `fish` (shell), `starship` (prompt), `btop`, `fastfetch`, `trash-cli`, `libcava`, `mpris-proxy`, `wpctl`/PipeWire
**Auth / portals** — `polkit` + `polkit-kde-agent`, `polkit-qt5`, `polkit-qt6`
**Fonts** — `ttf-jetbrains-mono-nerd`, `ttf-cascadia-code-nerd`, `ttf-material-symbols-variable`, `ttf-rubik-vf`
**Theming** — `qtengine` (Qt platform theme), `papirus-icon-theme`
**File manager** — `dolphin` (the stub's choice)

_~900 packages total. Notably **not** installed despite being referenced by the Caelestia config: `thunar`, `nemo`, `zen-browser`, `codium`/`vscodium`, `github-desktop`, `qps`, `pavucontrol`, `gammastep`, `geoclue`, `gnome-keyring`, `ydotool`, `hyprlauncher` (see Potentially broken)._

---

## Monitor config

- Single laptop panel **`eDP-1`** (a `BatteryMonitor` runs in the shell, confirming a laptop).
- No explicit `monitor =` line in the active stub → Hyprland default applies (`preferred, auto, 1`).
- The dormant Caelestia config also only sets the catch-all `monitor = , preferred, auto, 1` (scale 1).
- `~/.config/caelestia/monitors/eDP-1/shell.json` and the per-monitor override are empty (`{}`) — no per-display overrides.
- VRR enabled (`vrr = 1`) — but only in the dormant `misc.conf`, so not currently applied.

---

## Theming choices

- **Material You / Material 3 dynamic theming**, generated and kept in sync by Caelestia.
  - Active scheme: name **`shadotheme`**, flavour `default`, mode **dark**, variant **`tonalspot`**.
  - Palette: near-black blue background `#131317`, primary **periwinkle/lavender `#bfc1ff`**, tertiary **pink `#f4b2e2`**.
  - One source of truth (`~/.local/state/caelestia/scheme.json`) is fanned out to: Hyprland (`hypr/scheme/current.conf`), GTK 3 & 4 (`gtk.css`), Qt (`qtengine/caelestia.colors`), `foot`, and `fuzzel`.
- **Fonts:** JetBrains Mono Nerd Font for terminals (foot 12pt, fuzzel 17pt); the shell UI uses Material Symbols + Rubik. Shell font scale is **0.805** (deliberately shrunk); padding/rounding/spacing scales ~0.96–1.0.
- **Qt:** `qtengine` platform theme, style **Darkly**, icons **Papirus-Dark** (exported via uwsm env, so this *is* active).
- **GTK:** accent `#bfc1ff`, dark surfaces, plus a custom `thunar.css` (for a file manager that isn't installed).
- **Wallpaper:** `~/Pictures/Wallpapers/3d-tech.jpg` (managed by Caelestia under `~/.local/state/caelestia/wallpaper`).
- **Intended window styling (dormant):** 0.95 opacity, 15px rounding, blur (size 8 / 2 passes), shadows (range 20), gaps 5 in / 10 out / 20 single-window.

---

## Keybinds

### Active right now (from the stub) — `$mainMod = SUPER`

| Keys | Action |
|---|---|
| `Super + Q` | Open terminal → **kitty** |
| `Super + C` | Close active window |
| `Super + E` | File manager → **dolphin** |
| `Super + V` | Toggle floating |
| `Super + R` | `$menu` → **hyprlauncher** (not installed → no-op) |
| `Super + M` | `hyprshutdown` or fall back to exit Hyprland |

That's the entire active keymap (plus Hyprland built-in mouse defaults).

### Intended (Caelestia `keybinds.conf` — present but **not loaded**)

A much richer set is defined and ready, including:
- **Tap `Super`** → app launcher; `Super+V` clipboard history; `Super+.` emoji picker
- Apps: `Super+T` foot · `Super+W` zen-browser · `Super+C` codium · `Super+E` thunar · `Super+G` github-desktop
- Window/session: `Super+Q` close · `Super+L` lock · `Super+N` sidebar · `Super+K` show panels · `Ctrl+Alt+Del` session menu
- Special workspaces: `Super+S` scratchpad · `Super+M` music · `Super+D` comms · `Super+R` todo · `Ctrl+Shift+Esc` sysmon
- Capture: `Print` full screenshot · `Super+Shift+S` region · `Super+Alt+R` record w/ audio · `Super+Shift+C` color picker
- Workspaces 1–0 (+groups) via `wsaction.fish`, window groups via `Alt+Tab`, vim-style focus/move/resize, media/brightness/volume keys.

---

## Autostart

### Active (from the stub)
- `exec-once = caelestia shell` — the Quickshell daemon (bar, notifications, OSD, lock, idle monitor, battery, launcher backend).

### Intended (Caelestia `execs.conf` — **not loaded**)
- `gnome-keyring-daemon` (secrets) + polkit GNOME agent
- **Clipboard history** via `wl-paste --watch cliphist store` (text + image) — *currently not running, so clipboard history isn't being recorded*
- `trash-empty 30` (auto-purge trash > 30 days)
- Cursor theme setup, `geoclue` agent + `gammastep` (night light), `mpris-proxy` (Bluetooth media keys), `caelestia resizer` (PiP).

---

## Potentially broken / unusual

1. **🚨 The active Hyprland config is a stub that ignores the Caelestia config.**
   `~/.config/hypr/hyprland.conf` opens with *"This config is a STUB! This should never be generated."* — it's Hyprland's auto-generated fallback. It never does `source = ~/.config/hypr/hypr/hyprland.conf`, even though that symlink → `~/.local/share/caelestia/hypr/` exists and holds the real config.
   **Effect:** no Caelestia keybinds (launcher, screenshots, special workspaces, lock, media keys…), no window rules, no blur/shadow/gaps/rounding, no touchpad natural-scroll / repeat-rate tuning, and the autostart items above don't run.
   **Fix:** make the stub `source` the Caelestia entrypoint:
   ```conf
   source = ~/.config/hypr/hypr/hyprland.conf
   ```
   That entrypoint in turn sources `~/.config/caelestia/hypr-vars.conf` and `hypr-user.conf`, which don't exist yet — but `configs.fish` `touch`es them on load (see note 7), so it self-heals on first reload.

2. **Apps referenced by the Caelestia config aren't installed.** Once the config above is enabled, these binds/autostarts will fail: `thunar` & `nemo` (`Super+E` / `Super+Alt+E`), `zen-browser` (`Super+W`), `codium` (`Super+C`), `github-desktop` (`Super+G`), `qps`, `pavucontrol`, `ydotool` (alt-paste), `gammastep`+`geoclue` (night light), `gnome-keyring`. Install them or repoint the variables in `hypr-vars.conf`.

3. **`Super+R` does nothing today** — the stub's `$menu = hyprlauncher` isn't installed (`wofi` is installed but not wired up).

4. **kitty is the active terminal but `~/.config/kitty/` is empty** — kitty runs with stock defaults (unthemed). The themed terminal (foot) is only reachable via the dormant `Super+T` bind.

5. **Cursor theme `sweet-cursors` (size 24) is requested but not installed** — currently moot (that config is dormant); it'll fall back to the default cursor even after you enable the config.

6. **`fuzzel.ini` has two `[colors]` blocks** — a leftover One-Dark theme followed by the Caelestia theme. The second wins, so the first is dead config (harmless, worth deleting).

7. **Upstream bug in `~/.config/hypr/hypr/scripts/configs.fish`** — it never auto-reloads after first creating the user config files: `set -l _reload true` is scoped to the `if` block (so the outer `_reload` stays `false`), and `if _reload` runs a *command* named `_reload` instead of testing the variable. Low impact (the files still get created), but the intended `hyprctl reload` won't fire.

8. **Note (not broken):** Toolkit/theme env vars (`QT_QPA_PLATFORMTHEME=qtengine`, Wayland backends, `XDG_CURRENT_DESKTOP=Hyprland`, app2unit slices) are exported via `~/.config/uwsm/env*` and **are** active independent of the Hyprland stub — so Qt theming and Wayland-native app behavior work even while the rest of the config is dormant.

---

# Full setup pass — 2026-05-23

> **Environment constraint:** `sudo` requires a password in this session, so I could not directly change system state (enable services, edit `/etc`, install packages, edit PAM). All **user-space** work below is **done and verified live** (Hyprland 0.55.2 was running, so I `hyprctl reload`ed and tested). All **root-level** work is staged as reviewed, idempotent scripts for you to run — see **"Action items"** at the end.

## 1. WiFi — root cause & fix

**Root cause (two compounding issues):**
1. **Primary:** `iwd.service` was **disabled** — it never started at boot (confirmed: `systemctl is-enabled iwd` = `disabled`, and `journalctl -b -1 -u iwd` had *zero* entries). With no iwd, `wlan0` never associates, so `systemd-networkd`'s `DHCP=yes` has no carrier → no network. Your workaround (`systemctl restart iwd`) was literally just *starting* it.
2. **Secondary (explains the manual disconnect/reconnect):** a **dual IP-configuration conflict** — `/etc/iwd/main.conf` had `EnableNetworkConfiguration=true` (iwd doing its own DHCP) **and** `/etc/systemd/network/25-wireless.network` had `DHCP=yes` (networkd doing DHCP). Two managers fighting for `wlan0`'s IP → "associated but no IP until I reconnect."

**Ruled out:** rfkill (radio unblocked), `resolv.conf` (correct symlink → `stub-resolv.conf`), DNS (resolved working), driver (`iwlwifi` loaded fine). Power-management (`iwlwifi.power_save`) is **not** the cause — the symptom is "never comes up," not "drops randomly" — so I did **not** disable it (it would only cost battery).

**Fix (in `~/wifi-fix.sh`):** enable `iwd` at boot; set `EnableNetworkConfiguration=false` so **networkd owns DHCP / resolved owns DNS** (the stack you already enabled), making iwd association-only; ensure networkd+resolved enabled; confirm the saved profile's `AutoConnect`. The script backs up `main.conf` first and has a `test` mode that simulates a boot without rebooting.

## 2. Files created / modified (all user-space, done)

| File | Change |
|---|---|
| `~/.config/hypr/hyprland.conf` | Replaced the Hyprland stub with an entrypoint that sources the Caelestia config (old stub → `hyprland.conf.stub.bak`) |
| `~/.config/hypr/{variables.conf, hyprland, scripts}` + `scheme/default.conf` | **New symlinks** into the Caelestia dir — *without these the upstream config errored on every `source` line* (see Open-ended #1) |
| `~/.config/caelestia/hypr-user.conf` | All custom keybinds (unbind-then-`bindd`); sourced last so it wins |
| `~/.config/caelestia/hypr-vars.conf` | Commented override template (incl. cursor-theme-name hint) |
| `~/.config/caelestia/scripts/screenshot.fish` | grim+slurp → save to `~/Pictures/Screenshots/` + `wl-copy` (tested: produced a valid 1920×1080 PNG + put `image/png` on clipboard) |
| `~/.config/caelestia/scripts/kitty-theme.fish` | Regenerates kitty colours from `scheme.json` |
| `~/.config/kitty/{kitty.conf, current-theme.conf}` | kitty themed to match Caelestia (font/opacity mirror foot); colours generated from `scheme.json` |
| `~/.config/systemd/user/caelestia-kitty-theme.{path,service}` | Watches `scheme.json` and re-themes kitty on scheme change (**enabled & active**) |
| `~/.config/fuzzel/fuzzel.ini` | Removed the duplicate One-Dark `[colors]` block (backup: `fuzzel.ini.bak`) |
| `~/wifi-fix.sh`, `~/post-install-root.sh` | Staged root scripts (see Action items) |

## 3. Binds — substitutions & decisions (differs from what you asked)

- **Region screenshot:** `Ctrl+Shift_L` *registered* (modmask CTRL), but modifier-only binds can't be verified non-interactively and are known-flaky — so I **also** bound **`Ctrl+Shift+S`** to the same script as a guaranteed fallback. Test `Ctrl+Shift_L`; if it misfires, just delete its line.
- **`Super+P` → "Caelestia settings panel":** Caelestia has **no dedicated settings app** (config is the JSON files). I mapped it to the **Control Center** (`global, caelestia:controlCenter`) as the closest panel. Swap to `caelestia:dashboard` if you'd rather.
- **`Super+A` → launcher:** uses `global, caelestia:launcher` (identical to tap-Super).
- **Reassignments that removed Caelestia defaults** — heads up:
  - **`Super+L` was *lock*** → now Focus-right. **Lock no longer has a keybind.** (It still triggers on idle.) Want me to put lock on another key, e.g. `Super+Escape`?
  - `Super+K` was *toggle-all-panels* (showall) → now Focus-down.
  - `Super+P` was *pin window* → now Control Center.
  - `Super+arrows` were *movefocus* → now `swapwindow` (focus moved to `L/J/K/I`).
- **`Print` (fullscreen):** kept Caelestia's default (`caelestia screenshot`) per your instruction. Note it copies to clipboard but does **not** save a file. If you want fullscreen to also save, add to `hypr-user.conf`:
  `bindd = , Print, Fullscreen screenshot, exec, ~/.config/caelestia/scripts/screenshot.fish full`
- **PAM:** you said `/etc/pam.d/login`, but you log in via **SDDM** — so the keyring lines must go in **`/etc/pam.d/sddm`** (login wouldn't help graphical logins). `post-install-root.sh` targets `sddm` (and `login` too, for TTY).
- **Packages:** `qps` is in the **official `extra` repo** (not AUR) — name is fine. `sweet-cursors` doesn't exist on the AUR → use **`sweet-cursors-hyprcursor-git`** (right for hyprcursor). Verified `zen-browser-bin`, `vscodium-bin`, `github-desktop-bin` exist; all official packages confirmed.

## 4. Open-ended pass (mechanical fixes — review & revert if you disagree)

1. **Fixed the real reason the config was dormant.** The `hypr/hypr` symlink alone was *insufficient*: upstream's `hyprland.conf` uses `$hypr = ~/.config/hypr` and sources `$hypr/variables.conf`, `$hypr/hyprland/*.conf`, `$hypr/scripts/…` — paths that didn't exist (the files were one level down under `hypr/hypr/`). I added 4 relative symlinks so they resolve **and keep tracking upstream**. Reload now reports **zero config errors** (was 13).
2. **fuzzel** duplicate colour block removed.
3. **kitty** themed + live scheme-tracking watcher (mirrors how foot follows the scheme).
4. **Reviewed and left alone** (already sane in the now-active upstream config, and you said don't touch aesthetics): touchpad (natural-scroll, disable-while-typing, tap-to-click default on), VRR (`vrr=1`), animations/blur/rounding, brightness/volume/media keys (now functional via the shell IPC), idle-lock (handled by the shell). No changes needed.
5. **Lid close:** default `HandleLidSwitch=suspend` already works out of the box. Since your manual sleep bind uses *suspend-then-hibernate*, I staged that as a **commented** block in `post-install-root.sh` — uncomment if you want lid-close to match.
6. **Cursor theme name mismatch risk:** the config requests `sweet-cursors`, but the package installs a differently-cased dir (likely `Sweet-cursors`). Flagged with a ready-to-uncomment override in `hypr-vars.conf` + a verify step below.
7. **Upstream bug noted (not fixed, per your instruction):** `~/.config/hypr/hypr/scripts/configs.fish` never runs its post-creation `hyprctl reload` — `set -l _reload true` is block-scoped (outer stays `false`) and `if _reload` tests a *command*, not the variable. Cosmetic; report it upstream if you like.

## 5. Couldn't complete here (need your password / a reboot)

Nothing failed — these are simply blocked by the no-sudo constraint. Run, in order:

```bash
# 1. WiFi fix (then optionally simulate before rebooting)
! sudo bash ~/wifi-fix.sh
! sudo bash ~/wifi-fix.sh test        # optional: verify without rebooting

# 2. Install everything the config expects (qps is official; cursor pkg corrected)
! paru -S thunar nemo zen-browser-bin vscodium-bin github-desktop-bin qps \
          pavucontrol gammastep geoclue gnome-keyring ydotool \
          sweet-cursors-hyprcursor-git firefox

# 3. PAM keyring + ydotool daemon (+ optional lid) — AFTER step 2
! sudo bash ~/post-install-root.sh

# 4. Set the cursor theme (verify the real name first)
! ls /usr/share/icons | grep -i sweet
! gsettings set org.gnome.desktop.interface cursor-theme 'Sweet-cursors'
#   if the name above isn't "Sweet-cursors", also set $cursorTheme in
#   ~/.config/caelestia/hypr-vars.conf to match.

# 5. Reboot to confirm WiFi-on-boot
```

**Still unverifiable until then:** WiFi-on-boot (needs reboot — that's your test), `Ctrl+Shift_L` actually *firing* (interactive), and the app binds for not-yet-installed apps (`Super+B` firefox, `Super+E` thunar) — they're registered and will work once installed.

---

# WiFi panel fix + an IPv4 bug I found — 2026-05-23

## Root cause (panel): Caelestia's WiFi UI is NetworkManager-only
The shell's entire network stack (`services/Nmcli.qml`, `services/Network.qml`, `utils/NetworkConnection.qml`, `services/VPN.qml`) shells out to **`nmcli`**. There is **zero** iwd/iwctl/connman code anywhere and **no backend toggle**. You run iwd (NetworkManager is installed but inactive), so every widget call returns `Error: NetworkManager is not running.` → blank panel. (Your "no periodic scan" hypothesis was wrong; it's the hardcoded-NetworkManager case.)

## Decision: keep iwd, add an iwd front-end (you chose this)
Patching the QML to speak iwd would mean rewriting ~600 lines in a root-owned `/etc/xdg/` tree that `caelestia-shell` overwrites on update — out of scope. Switching to NetworkManager+iwd-backend would rework your boot/IP stack. So instead:

- **`Super+Shift+W` → `foot --app-id impala -e impala`** (impala = the official `extra` TUI front-end for iwd), in a floating, centered terminal. Added to `~/.config/caelestia/hypr-user.conf` with `float/size/center` window rules for `class:impala`. Bind verified registered; `hyprctl configerrors` clean.
- **Verified the iwd path works for your user *without sudo*:** `iwctl station wlan0 scan` succeeded and listed 6 networks incl. the connected `Fizz0499 5G` (marked `>`). iwd's D-Bus policy allows `group=wheel` and you're in `wheel`, so **no `usermod -aG network` is needed** (your step-3 concern doesn't apply here). impala uses this same D-Bus path, so it'll work once installed.
- **Did NOT hide the dead bar widget** — there's no `shell.json` toggle for it, and editing the root QML is fragile/overwritten on update. The bar's WiFi icon will show a "disconnected" state even when you're online (cosmetic). Left as-is intentionally.

## ⚠️ Separate bug I found while honoring "don't break WiFi": IPv4 is currently down
Checking the connection, `networkctl status wlan0` showed **`Network File: n/a` / `routable (unmanaged)`** — systemd-networkd isn't managing wlan0, so **no DHCPv4 runs**. networkd's own log says why:
```
/etc/systemd/network/25-wireless.network:4: Unknown key 'name' in section [Match], ignoring.
… No valid settings found in the [Match] section, ignoring file.
```
The file uses lowercase **`name=wlan0`**; systemd requires **`Name=`**, so it discards the whole file. IPv6 works via SLAAC (so dual-stack HTTPS succeeds and it *looks* online), but there's no IPv4.

- **This is a defect in my previous `wifi-fix.sh`, and I own it:** I set `EnableNetworkConfiguration=false` (iwd stops doing DHCP) on the assumption networkd would take over, without verifying networkd actually matched wlan0. It never did (this typo predates everything, logged since the 21:14 boot). Before the fix, iwd's own DHCP supplied IPv4; after it, nothing does. **WiFi-on-boot is therefore currently IPv6-only.**
- **Not caused by this task:** the `unmanaged` state dates to the 23:16 networkd restart (your `wifi-fix.sh test`); my read-only `scan` doesn't restart networkd.
- **Fix staged:** `~/fix-networkd-wlan0.sh` corrects `name=` → `Name=`, reloads networkd, and waits for the DHCPv4 lease. One-line change; backs up the file first.

## Your action items
```bash
# 1. WiFi UI (one official package) — then press Super+Shift+W to verify it lists networks
! sudo pacman -S impala
#    optional GUI alternative instead of / alongside the TUI:
! paru -S iwgtk

# 2. Restore IPv4 (also fixes IPv4-on-boot) — re-verify connection after
! sudo bash ~/fix-networkd-wlan0.sh
! ip -4 addr show wlan0        # expect an 'inet 192.168.x.x'
! iwctl station wlan0 show     # expect State: connected
```

## Verification done here (no changes to networking)
- iwd / networkd / resolved still `enabled`; `iwctl station wlan0 show` = **connected** (`Fizz0499 5G`) throughout.
- `Super+Shift+W` bind registered & labeled; config reloads with zero errors.
- Unprivileged iwd scan returns the current + neighboring networks — confirming impala will populate.

## Files created / modified
- `~/.config/caelestia/hypr-user.conf` — added `Super+Shift+W` (impala) + `class:impala` float rules.
- `~/fix-networkd-wlan0.sh` — staged one-line networkd `Name=` fix (needs sudo).


# SDDM astronaut login theme — 2026-05-24

Installed and configured `sddm-astronaut-theme` as the SDDM greeter, variant **black_hole**. The SDDM service itself and the existing PAM keyring lines in `/etc/pam.d/sddm` were left untouched.

## What got installed and where
- **`sddm-astronaut-theme`** via `paru -S sddm-astronaut-theme` (AUR; maintainer D3vil0p3r). Installed version **82.8c85b9c-1** (the AUR `pkgver()` tracks latest upstream git, so it's newer than the `-Si` listing).
- Theme files: **`/usr/share/sddm/themes/sddm-astronaut-theme/`** (`metadata.desktop` present and verified). Bundled fonts also dropped into `/usr/share/fonts/`.

## Qt6 dependencies
The theme requires: `sddm qt6-5compat qt6-declarative qt6-multimedia-ffmpeg qt6-svg qt6-virtualkeyboard`. All satisfied — **no separate manual dep step was needed**:
- Already present before this task: `qt6-multimedia-ffmpeg`, `qt6-svg` (plus `qt6-multimedia`).
- Pulled in automatically by paru during the build: `qt6-5compat`, `qt6-declarative`, `qt6-virtualkeyboard`.
- `qt6-multimedia-ffmpeg` is what lets the video-background variants play; with it missing the theme can fail to load and SDDM falls back to default.

## Background variants found (`Themes/*.conf` → `Backgrounds/`)
- `astronaut` (astronaut.png, static — theme default)
- **`black_hole` (black_hole.png, static — CHOSEN)**
- `cyberpunk` (cyberpunk.png, static)
- `hyprland_kath` (hyprland_kath.mp4, video)
- `jake_the_dog` (jake_the_dog.mp4, video)
- `japanese_aesthetic` (japanese_aesthetic.png, static)
- `pixel_sakura` (pixel_sakura.gif, animated)
- `pixel_sakura_static` (pixel_sakura_static.png, static)
- `post-apocalyptic_hacker` (post-apocalyptic_hacker.png, static)
- `purple_leaves` (purple_leaves.png, static)

Variant mechanism for this version (1.3): the active variant is the `ConfigFile=Themes/<variant>.conf` line in `metadata.desktop`. There's no SDDM-level override for that line, so the variant is set by editing `metadata.desktop` (what upstream's own `setup.sh` does).

## What the staged script does — `~/set-sddm-astronaut.sh` (NOT run)
Run as root from a TTY: `sudo bash ~/set-sddm-astronaut.sh`. It:
1. Writes `/etc/sddm.conf.d/theme.conf` with `[Theme]` / `Current=sddm-astronaut-theme` (creating `/etc/sddm.conf.d/`, which didn't exist). Backs up any existing `theme.conf` to `theme.conf.bak-<timestamp>` first.
2. Backs up `metadata.desktop` to `metadata.desktop.bak-<timestamp>`, then sets `ConfigFile=Themes/black_hole.conf`.
3. Sanity-checks (must be root, theme + variant `.conf` must exist) and prints the final line:
   `Theme set. Test with: sudo systemctl restart sddm  (WARNING: this kills your session — only run from a TTY or after saving work).`

It deliberately does **not** restart SDDM. ⚠️ Caveat: `metadata.desktop` is package-owned, so a future theme upgrade can reset the variant to `astronaut` — just re-run this script if that happens.

## Exact steps for you to test
1. **Save any open work** in the current Hyprland session — the restart below kills it.
2. Apply the config: `sudo bash ~/set-sddm-astronaut.sh`
3. Switch to a text console: **Ctrl+Alt+F2**, then log in with your username/password.
4. Restart the greeter from that TTY: `sudo systemctl restart sddm`
5. SDDM relaunches on its VT (usually Ctrl+Alt+F1) showing the **black_hole** astronaut theme. Log in there to confirm the graphical session comes back up normally.
6. If the theme fails / you get a blank or default greeter: from the TTY, inspect `journalctl -b -u sddm` and either re-run the script or revert with `sudo rm /etc/sddm.conf.d/theme.conf` (and restore `metadata.desktop` from its `.bak-<timestamp>`), then `sudo systemctl restart sddm`.

---

# Pretty + instant boot (Plymouth splash + hidden bootloader menu) — 2026-05-24

Staged script: `~/setup-pretty-boot.sh` — **not run**. Apply with `sudo bash ~/setup-pretty-boot.sh`, then reboot when ready.

## Investigation (read-only)
- **Bootloader detected: systemd-boot.** `/boot/loader/loader.conf` exists; no `/etc/default/grub`, no `/boot/grub/`. ESP `/dev/nvme0n1p1` (vfat) mounted at `/boot`.
- **GPU / KMS:** Intel UHD 620 (WhiskeyLake-U), driver `i915` loaded; `kms` HOOK already present → Plymouth renders at native resolution early. **No red flags.**
- **plymouth** not installed; `paru` available; only `breeze-plymouth` is a theme in official repos (Arch-flavored themes are AUR-only). No Hyprland-specific Plymouth theme exists in the AUR.
- Kernels: `linux` only (no LTS). Microcode is folded into the initramfs via the `microcode` HOOK, so entries have no separate `intel-ucode.img` initrd line.

## Theme chosen
- **`arch-charge-big`** — AUR pkg `plymouth-theme-arch-charge-big` (most popular animated Arch theme; big Arch logo with a pulsing "charge" ring). Built as the normal user (`makepkg` refuses root); the official `plymouth` package is installed via pacman.

## Files the script modifies (each backed up to `<file>.bak.<timestamp>`)
1. `/etc/mkinitcpio.conf` — insert `plymouth` into HOOKS after `udev`, before `autodetect`.
2. `/boot/loader/entries/2026-05-23_15-15-17_linux.conf` (primary entry) — append `quiet splash` to `options`.
3. `/boot/loader/loader.conf` — `timeout 0` + explicit `default 2026-05-23_15-15-17_linux.conf` (makes the hidden-menu boot deterministic).
4. `/boot/loader/entries/arch-safe.conf` — **created**: "Arch Linux (Safe / Verbose Boot)", same kernel/initrd, options WITHOUT `quiet splash`.

Initramfs is rebuilt by `plymouth-set-default-theme -R arch-charge-big` (no manual `mkinitcpio` run). The script verifies the rebuilt `initramfs-linux.img` actually contains plymouth **before** touching the bootloader — so a failed rebuild leaves the bootloader untouched and the system boots exactly as before.

## Kernel cmdline — before / after
- **Before (all entries):** `root=PARTUUID=2e4997b8-4d7c-44ad-a84b-0234c3183b74 zswap.enabled=0 rw rootfstype=ext4`
- **After — primary entry (splash):** `root=PARTUUID=…b74 zswap.enabled=0 rw rootfstype=ext4 quiet splash`
- **After — `arch-safe.conf` (verbose):** `root=PARTUUID=…b74 zswap.enabled=0 rw rootfstype=ext4`  (unchanged → full verbose output)
- The pre-existing `linux-fallback` entry is left untouched (also verbose) as an extra recovery path.

## loader.conf — before / after
- Before: `timeout 3`
- After: `timeout 0` + `default 2026-05-23_15-15-17_linux.conf`

## Recovery
The bootloader menu is hidden (`timeout 0`). **Hold SPACE during boot** to reveal the menu, then pick **"Arch Linux (Safe / Verbose Boot)"**. Deeper fallbacks: pick **"Arch Linux (linux-fallback)"**, or press **`e`** at the menu to remove `splash` from a cmdline for a single boot. The script never reboots or restarts anything.

## To apply
`sudo bash ~/setup-pretty-boot.sh`  → then reboot when ready. (Idempotent: safe to re-run.)

---

# Battery diagnosis & power tuning — 2026-05-24

## Verdict (read this first)
**The battery is worn out: ~5.3% of its original capacity. Replace it.** Software tuning
cannot meaningfully help. The identical symptom on Windows confirms this is hardware
degradation, not the OS. No abnormal drain was found — the short runtime is fully
explained by lost capacity.

## Battery health — the numbers behind it
Source: `/sys/class/power_supply/BAT0/uevent` (this pack reports *charge* in µAh, not energy).

| Field | Value |
|---|---|
| Design capacity (`charge_full_design`) | 3684 mAh  (≈ 42.0 Wh @ 11.4 V) |
| Current full capacity (`charge_full`)  | **195 mAh** (≈ 2.2 Wh) |
| **Health = charge_full / charge_full_design** | **195 / 3684 = ~5.3%** |
| Cycle count | 0 reported (Dell/BYD EC doesn't expose it — not meaningful) |
| Manufacturer | BYD |
| Model name | DELL FW8KR94 |
| Serial | 6459 |
| Technology / design voltage | Li-ion / 11.4 V |

New battery = 100%; replacement territory is < ~50%. At **~5.3%** this cell is effectively dead.

## Power draw — expected vs observed runtime
Measured on battery (`current_now` × `voltage_now`; `power_now` not exposed by this EC).
Sampled over ~10 s under light load (Firefox + Hyprland + compositor running):

- Samples: 10.0–10.8 W steady-state (first post-unplug sample 5.6 W = settle); **avg ≈ 10.5 W**.
- Usable energy now ≈ **2.2 Wh**.
- **Expected runtime** = 2.2 Wh / 10.5 W ≈ **13 min** (less under load, more at true idle).
- **Observed runtime** ≈ **15 min**.
- → **They match.** Runtime is capacity-limited; there is no hidden software drain.

## Drain anomalies
**None.** Checks performed:
- Top CPU: normal (Firefox, Hyprland, kitty, caelestia `qs`) — nothing rogue.
- `journalctl -p 4 -b`: only benign noise (dbus service-name warnings, psmouse, an
  informational `nvme … unchecked data buffer`). No hardware-misbehavior signs.
- GPU (Intel UHD 620, `i915`, card1): power_state D0 / runtime active — expected while in use.
- powertop was **not** installed (the tuning script installs it for future live diagnostics).

## Laptop model + replacement-battery search terms
- Vendor / model: **Dell Inc. — Inspiron 7586** (Inspiron 13 7586 2-in-1).
- Spec to match: **42 Wh, 11.4 V, 3-cell** Li-ion (design 3684 mAh).
- Suggested searches:
  - `Dell Inspiron 13 7586 battery 42Wh 11.4V replacement`
  - `Dell Inspiron 7586 2-in-1 battery`
  - cross-reference the sysfs model string **`DELL FW8KR94`** (mfr BYD)
- **Confirm the Dell part number printed on the physical battery** before buying — that
  label is the authoritative match.

## `~/tune-power.sh` — what it does & how to apply
Path: `~/tune-power.sh` (staged, **not run automatically**). Apply with:

```
sudo bash ~/tune-power.sh
```

Idempotent and reversible. Chosen approach: **drive power-profiles-daemon (ppd), skip TLP.**
Rationale: ppd is already installed as a **hard dependency of `caelestia-shell`** and TLP
conflicts with it, so installing TLP would mean masking ppd (risking Caelestia). The script:
1. Installs **powertop** (official repo) for live diagnostics.
2. Ensures **power-profiles-daemon** is unmasked + enabled.
3. Installs an **AC/battery auto-switcher** (udev rule + `ppd-ac-switch.service`):
   **balanced on AC** (= EPP `balance_performance`), **power-saver on battery** (= EPP `power`).
   Balanced-on-AC avoids needlessly throttling the machine while plugged in — which, with a
   dead battery, is nearly all the time.

Deliberately left alone (by request): **TLP / tlp-rdw not installed**, **systemd-rfkill not
masked** (TLP-only), **ppd package kept**, **brightness untouched** (Caelestia), **WiFi/iwd
power management untouched**. No reboot.

**Realistic gain from this tuning: a couple of minutes at most** — even halving idle draw to
~5 W only moves runtime from ~13 min to ~26 min on a 2.2 Wh pack. Budget for a new battery.

Revert: `systemctl disable --now ppd-ac-switch.service` then remove
`/etc/systemd/system/ppd-ac-switch.service`, `/etc/udev/rules.d/99-ppd-ac-switch.rules`,
`/usr/local/bin/ppd-ac-switch`, then `systemctl daemon-reload && udevadm control --reload-rules`.

---

## 6. Dotfiles repository (`~/dotfiles`)

This whole setup is now captured in a git repo at **`~/dotfiles`**, ready to push
to a **private** GitHub repo. Goal: clone on a fresh Arch install, run one script,
run the root scripts it points to, reboot — same system.

**Tracked:**
- `config/` — personal configs only, copied (not symlinked):
  `hypr/hyprland.conf` (the entrypoint, not the upstream symlinks), the whole
  `caelestia/` override dir, `kitty/`, `fuzzel/fuzzel.ini`, `foot/foot.ini`, and
  the user systemd units `caelestia-kitty-theme.{path,service}`.
- `packages/` — `pacman-explicit.txt` (`pacman -Qqen`, 70 pkgs) and
  `pacman-foreign.txt` (`pacman -Qqem`, 9 AUR/foreign pkgs), plus
  `refresh-package-lists.sh` to regenerate them.
- `scripts/` — the six root setup scripts from this session (`wifi-fix.sh`,
  `fix-networkd-wlan0.sh`, `set-sddm-astronaut.sh`, `setup-pretty-boot.sh`,
  `tune-power.sh`, `post-install-root.sh`).
- `install.sh` — the rebuild entrypoint (installs packages, lays down configs,
  enables user services; prints the root steps to run by hand).
- `README.md`, `.gitignore`, and this `setup-snapshot.md`.

**NOT tracked (intentional):**
- Machine-specific **state**: saved WiFi PSKs in `/var/lib/iwd/`, browser
  profiles, caches, `**/state/`, history — won't transfer, rebuilt at first boot.
- **Wallpapers** (`caelestia/wallpaper*`) — large/personal.
- **Secrets** (`secrets/`, `.env*`, `*.pem`, `*.key`) — gitignored, defense in depth.
- **Upstream Caelestia** (`~/.local/share/caelestia/`) — reinstalled fresh by the
  package step; only the personal overrides are tracked.

The user systemd `ydotool.service` is enabled but provided by the `ydotool`
package (lives in `/usr/lib/systemd/user/`), so it isn't copied — `install.sh`
re-enables it after the package is installed.

**New-laptop workflow:** see `README.md` → "Restoring on a fresh laptop". In short:
archinstall → temp internet → install paru → `git clone … ~/dotfiles` →
`bash install.sh` → run the six root scripts in order → reboot.

A secrets scan was run over the repo before the first commit; the only matches
were the literal words "password"/"secrets" in comments and prose (no credentials),
and no `/home/sean/` or `sean@` strings are hardcoded anywhere (configs use
`~`/`%h`/`$HOME`).

---

## 7. Switching WiFi UX to NetworkManager (iwd backend) — STAGED 2026-05-24

**Status: staged, not yet executed.** Script written to `~/switch-to-networkmanager.sh`;
to be run manually in a real terminal (`sudo bash ~/switch-to-networkmanager.sh`).
This section will be finalized after the run is confirmed stable for a few days.
The dotfiles repo is intentionally **not** updated yet.

### Why
Caelestia's bar WiFi widget only speaks `nmcli` (NetworkManager). The system was
iwd-only (see [section 2/3 on the iwd stack]), so the widget stayed blank. Goal:
let NetworkManager own the WiFi UX while iwd keeps doing the actual radio
association underneath.

### New mental model (after migration)
- **NetworkManager** = WiFi UX + IP/DHCP for wlan0 (what the widget talks to).
- **iwd** = just the radio/association driver (NM's `wifi.backend=iwd`). Still
  enabled; its `/var/lib/iwd/` profiles (incl. `Fizz0499 5G`) are reused, not deleted.
- **systemd-resolved** = still the DNS resolver; NM feeds it via `dns=systemd-resolved`.
  `/etc/resolv.conf` stays the resolved stub symlink (untouched).
- **systemd-networkd** = retired for wlan0 (NM does IP now). Disabled at cutover.

### What the script does (ordered for safety; auto-rollback on any failure)
1. Preflight: abort unless currently online; timestamped backups to
   `/root/switch-to-nm-backups/<ts>/` of `25-wireless.network`, `iwd/main.conf`,
   `/etc/NetworkManager/`, unit states, and `iwctl known-networks list`.
2. `pacman -S --needed networkmanager` (already installed as a caelestia-shell dep).
3. Drop-ins: `/etc/NetworkManager/conf.d/wifi-backend.conf` (`wifi.backend=iwd`)
   and `dns.conf` (`dns=systemd-resolved`).
4. Start NM and prove it's functional (running, sees wlan0, scans) **while still
   online via networkd**.
5. Cutover: `disable --now systemd-networkd`, then activate `Fizz0499 5G` through
   NM reusing iwd's stored PSK (no password in the script).
6. Verify: `nmcli` state connected + wlan0 has IPv4 + `ping 1.1.1.1` + `ping github.com`.
   Any failure -> automatic rollback.

### Files changed by a successful run
- `+ /etc/NetworkManager/conf.d/wifi-backend.conf`
- `+ /etc/NetworkManager/conf.d/dns.conf`
- `NetworkManager.service` enabled; `systemd-networkd.service` disabled.
- iwd, resolved, `/var/lib/iwd/`, `/etc/iwd/main.conf`, `25-wireless.network`: **unchanged**
  (the latter two backed up only; iwd's `EnableNetworkConfiguration=false` is already
  correct for the NM-backend world).

### Rollback (restores iwd-only in well under 30s)
    sudo bash ~/switch-to-networkmanager.sh rollback
Disables NM, removes the two conf.d drop-ins, restarts iwd (resumes standalone
autoconnect) + nudges `iwctl station wlan0 connect "Fizz0499 5G"`, re-enables
networkd + resolved, restores backups, waits and verifies ping. Runs automatically
if the forward migration fails verification.

### Recovery if WiFi breaks on next boot
Boot to a console (hold Space at the bootloader for a working/Safe entry, or
Ctrl+Alt+F2 to a TTY and log in), then run the rollback command above.

### Known caveat
If the iwd backend doesn't hand its stored PSK to NM automatically, the run
rolls back and prints the one manual command to finish the switch yourself
(`nmcli device wifi connect "Fizz0499 5G" password '<...>'`) — the password is
never written into the script.

### Update 2026-05-24 (later): v1 failed — real cause was a power-tuning cycle

First migration attempt failed at `systemctl enable --now NetworkManager` with
"Transaction order is cyclic"; rollback worked, stayed online on iwd. The assumed
cause (NM and networkd can't both be enabled) was **wrong** — the journal showed
no NM/networkd cycle. The real culprit is a pre-existing **systemd ordering cycle**
from `tune-power.sh`'s `ppd-ac-switch.service`:

    ppd-ac-switch.service  After  power-profiles-daemon.service   (our unit)
    power-profiles-daemon  After  multi-user.target               (upstream PPD unit)
    multi-user.target      After  ppd-ac-switch.service           (it's WantedBy=multi-user.target)

= a closed loop systemd can't resolve. It poisons ANY transaction that pulls in
`multi-user.target` — and `enable --now NetworkManager` does exactly that. It had
also been silently deleting ppd-ac-switch's boot job every boot, so the AC/battery
auto-switcher had **never actually run at boot** (`ActiveEnterTimestamp` empty).

**Fix staged:** `~/fix-ppd-cycle.sh` — changes ppd-ac-switch.service `[Install]`
from `WantedBy=multi-user.target` to `WantedBy=power-profiles-daemon.service` (runs
right after PPD, no multi-user ordering edge → loop gone). Self-verifying; reverts
if a cycle remains. Side benefit: the AC switcher will now run at boot.

**WiFi script rewritten to v2** (`~/switch-to-networkmanager.sh`): NM is configured
but NOT started until a tight cutover that never has both units enabled when
anything starts — `disable systemd-networkd` (no --now) -> `enable NetworkManager`
(no --now) -> `daemon-reload` -> `stop systemd-networkd` -> `start NetworkManager`.
Dropped v1's "prove NM works while still online" probe (impossible now — can't
start NM while networkd is enabled; the cutover itself is the test). Offline window
grows to ~15-20s during cutover; auto-rollback (now also handling a halfway-cutover
state) restores connectivity in <30s on any failure.

**Run order when ready:** `sudo bash ~/fix-ppd-cycle.sh` first, then
`sudo bash ~/switch-to-networkmanager.sh`. Still not run yet; dotfiles repo
untouched. NOTE: the repo's `scripts/tune-power.sh` still emits the buggy unit and
must be patched before it's used on a fresh install.

---

## 8. Cleaning up dead EFI boot entries — STAGED 2026-05-24

**Status: staged, not yet executed.** Script: `~/clean-efi-entries.sh`
(`sudo bash ~/clean-efi-entries.sh`). NVRAM-only; touches no files on the ESP.

### Diagnosis (read-only, confirmed)
`efibootmgr` showed three dead entries left over from prior OSes, plus the working
fallback and firmware generics:

    Boot0000* Windows Boot Manager   -> \EFI\Microsoft\Boot\bootmgfw.efi
    Boot0001  ubuntu                 -> \EFI\ubuntu\shimx64.efi
    Boot0008  Garuda                 -> \EFI\Garuda\grubx64.efi
    Boot0009* UEFI: ...TOSHIBA...    -> \EFI\Boot\BootX64.efi   (working fallback)
    Boot000A-000D                    firmware generics (Floppy/USB/CD/NIC)

`/boot/EFI/` contains only `BOOT/`, `Linux/`, `systemd/` — **no** `Microsoft`,
`ubuntu`, or `Garuda` dirs, so those three entries are dead pointers. The fallback
loader `\EFI\Boot\BootX64.efi` resolves to `/boot/EFI/BOOT/BOOTX64.EFI` (137216 B),
byte-identical to `systemd/systemd-bootx64.efi` (vfat is case-insensitive → same
file). BootOrder was `0008,0001,0000,0009,000A..` (firmware tried the 3 dead
entries before falling through to working Arch — ugly but functional).

### What the script does (NVRAM only)
1. Verifies (before any change): the 3 dead ESP dirs are absent; the fallback
   Boot0009 + its loader file exist; and each of Boot0000/0001/0008 still carries
   its expected label (Windows/ubuntu/Garuda) — refuses to delete a renumbered
   entry. Aborts with no changes if anything is off (incl. if a leftover
   Microsoft/ubuntu/Garuda dir is found).
2. Backs up `efibootmgr -v` to `/root/efi-backups/efibootmgr-before-<ts>.txt`.
3. Deletes Boot0000, Boot0001, Boot0008.
4. Creates a named entry `Arch Linux` -> disk nvme0n1 part 1, loader
   `\EFI\Boot\BootX64.efi` (the existing fallback binary), reading its new BootXXXX
   number dynamically (skips creation if an `Arch Linux` entry already exists).
5. Sets BootOrder = `<new>,0009,000A,000B,000C,000D` (Arch first, working fallback
   Boot0009 kept SECOND as backup, firmware generics last).
6. Saves an after snapshot and prints a recovery note.

### Safety / what is NOT done
- Boot0009 (working fallback) is **kept** until a reboot proves the new entry.
- Firmware entries 000A-000D left alone (regenerated each boot anyway).
- No file on the ESP is modified — NVRAM variables only.
- Deleting Boot0009 is deliberately **not** scripted yet; decide after reboot.

### Recovery
Bootloader files are untouched and Boot0009 still boots Arch via the same
`\EFI\Boot\BootX64.efi`, so the machine boots even if the new entry is wrong.
Restore the old order from the before-`.txt`: `efibootmgr -o <BootOrder line>`.

## Idle / lock / screen-off timers (2026-05-24)

**Mechanism:** This system has **no hypridle/swayidle/hyprlock** installed. Idle,
lock, DPMS and suspend are all handled *inside Caelestia Shell* (`qs -c caelestia`,
via `kidletime`). The driver is `/etc/xdg/quickshell/caelestia/modules/IdleMonitors.qml`,
which iterates `GlobalConfig.general.idle.timeouts`. Action strings like `dpms off`
go to `hyprctl dispatch`; `lock`/`unlock` are special-cased; an array (e.g.
`["systemctl","suspend-then-hibernate"]`) is run via `execDetached`.

**Config file (user-owned, hot-reloaded, survives reboots & pkg upgrades):**
`~/.config/caelestia/shell.json` -> key `general.idle.timeouts`.
Also mirrored to the canonical repo `~/dotfiles/config/caelestia/shell.json`
(install.fish copies it, so the repo copy must match or it would revert).
A `QVariantList` override **replaces the whole array**, so all three entries are listed.

**Before (caelestia-shell 1.6.2 compiled defaults — idle was not overridden):**
| timeout | idleAction | returnAction |
|---------|-----------|--------------|
| 180s (3m)  | lock | — |
| 300s (5m)  | dpms off | dpms on |
| 600s (10m) | systemctl suspend-then-hibernate | — |

**After:**
| timeout | idleAction | returnAction |
|---------|-----------|--------------|
| **900s (15m)**  | lock | — |
| **1800s (30m)** | dpms off | dpms on |
| **2700s (45m)** | systemctl suspend-then-hibernate | — |

Suspend was raised 600->2700 because 600 < 1800 would have suspended before
screen-off. `lockBeforeSleep:true` and `inhibitWhenAudio:true` left at defaults.

**Apply / verify:** No daemon to restart — Caelestia hot-reloads shell.json
(confirmed: shell PID unchanged, file re-serialized by the shell itself).
Backup of the pre-change file: `~/.config/caelestia/shell.json.bak-20260524-165452`.

## Trackpad gesture: 3-finger workspace swipe (2026-05-24)

**Goal:** 3-finger horizontal swipe = switch workspace (a touchpad twin of the
SUPER+SHIFT+LEFT/RIGHT binds), with smooth finger-tracking. Keyboard binds untouched.

**Hyprland 0.55.2 note (plan was written for the old syntax):** the old
`gestures { workspace_swipe = true; workspace_swipe_fingers = N }` options were
**removed** — `hyprctl getoption gestures:workspace_swipe` returns "no such option".
Enabling + finger count is now done entirely by the `gesture =` keyword. Caelestia
upstream already enables workspace swipe, but on **4 fingers**
(`gesture = $workspaceSwipeFingers, horizontal, workspace`, `$workspaceSwipeFingers=4`
in ~/.local/share/caelestia/hypr/variables.conf). 3-finger horizontal was unused.

**Change made — one line in `~/.config/caelestia/hypr-user.conf`** (mirrored to
`~/dotfiles/config/caelestia/hypr-user.conf`):

    gesture = 3, horizontal, workspace

Additive: the upstream 4-finger horizontal swipe and the 3-finger up/down
special-workspace gestures still work (distinguished by finger count + direction).

**Tuning (global to all workspace swipes; LEFT at Caelestia upstream values in
~/.local/share/caelestia/hypr/hyprland/gestures.conf — deliberately not overridden):**
distance=700, cancel_ratio=0.15, min_speed_to_force=5, create_new=true, invert=true,
forever=false. create_new+forever give parity with the keyboard binds (create new
workspace at the right edge; stop at workspace 1 on the left).

**Apply / verify:** `hyprctl reload` (done; no logout). `hyprctl configerrors` was
clean. There's no hyprctl command to list registered gestures in 0.55 — test by
swiping. Touchpad: dell0895:00-04f3:30b6-touchpad.

**Revert:** delete the `# --- Trackpad gestures ---` block (the `gesture = 3,
horizontal, workspace` line) from hypr-user.conf, then `hyprctl reload`.
Backup of pre-change file: ~/.config/caelestia/hypr-user.conf.bak-20260524-173245

## Disable 3-finger vertical gestures (2026-05-24)

**Goal:** kill the 3-finger up/down gestures (open/toggle the special "dashboard"
workspace); keep 3-finger horizontal (workspace swipe), 4-finger gestures, scroll, drag.

**Where they live:** purely Hyprland-level `gesture =` lines in upstream
`~/.local/share/caelestia/hypr/hyprland/gestures.conf` — NOT shell QML (grep for
gesture/swipe/fingers in /etc/xdg/quickshell/caelestia/ returns nothing, so there is
no shell.json flag for this). The two lines (with $gestureFingers=3):
  gesture = 3, up,   special, special                         # -> special workspace
  gesture = 3, down, dispatcher, exec, caelestia toggle specialws  # -> toggle specialws

**How disabled (Hyprland 0.55, no upstream edit):** the gesture system (reworked in
0.51) has an `unset` action that removes a previously-set gesture; it must EXACTLY
match the original's finger count + direction. Added to `~/.config/caelestia/hypr-user.conf`
(mirrored to ~/dotfiles/config/caelestia/hypr-user.conf), which is sourced (hyprland.conf
line 34) AFTER gestures.conf (line 29):

    gesture = 3, up, unset
    gesture = 3, down, unset

fingers=3 + up/down only -> does NOT affect 4-finger-down suspend or the 3-finger
horizontal workspace swipe. (Note: `gestures:workspace_swipe*` enable/finger options
were removed in 0.51; `hyprctl gestures` query does not exist; `unbind` is keybinds-only
— `unset` is the supported way to drop a gesture.)

**Apply / verify:** `hyprctl reload` (done; configerrors clean). `hyprctl keyword gesture
"3, up, unset"` returned ok when tested live. Test by swiping: 3-finger up/down = nothing;
3-finger left/right still switches workspaces; 4-finger still works.

**Revert (one line):** delete the two `gesture = 3, up/down, unset` lines from
hypr-user.conf, then `hyprctl reload`.
Backup of pre-change file: ~/.config/caelestia/hypr-user.conf.bak-20260524-173838
