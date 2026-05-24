# dotfiles

Personal **Arch + Hyprland + Caelestia** dotfiles for a **Dell Inspiron 13 7586**.
WiFi via **iwd**; IP/DNS via **systemd-networkd + systemd-resolved**; display
manager **SDDM** with the **sddm-astronaut-theme** (`black_hole` variant); boot
splash via **Plymouth** (`arch-charge-big` theme).

This repo is *Level-2 reproducible*: on a fresh Arch install you can clone it,
run one script, run a handful of root scripts it points you to, reboot, and end
up with the same system.

## Repository layout

```
~/dotfiles/
├── README.md
├── .gitignore
├── install.sh                      # the "rebuild on new laptop" entrypoint
├── packages/
│   ├── pacman-explicit.txt         # `pacman -Qqen` (official, explicitly installed)
│   ├── pacman-foreign.txt          # `pacman -Qqem` (AUR + foreign, explicitly installed)
│   └── refresh-package-lists.sh    # regenerates the two .txt files
├── config/
│   ├── hypr/                       # only hyprland.conf (the personal entrypoint)
│   ├── caelestia/                  # entire dir minus state/wallpaper
│   ├── kitty/                      # kitty.conf + current-theme.conf
│   ├── fuzzel/                     # fuzzel.ini
│   ├── foot/                       # foot.ini
│   └── systemd-user/               # caelestia-kitty-theme.{path,service}
├── scripts/                        # root-level setup scripts (run with sudo)
│   ├── wifi-fix.sh
│   ├── fix-networkd-wlan0.sh
│   ├── set-sddm-astronaut.sh
│   ├── setup-pretty-boot.sh
│   ├── tune-power.sh
│   └── post-install-root.sh
└── setup-snapshot.md               # full history of how this setup was built
```

## Restoring on a fresh laptop

1. **Install Arch** with `archinstall` (any sane choice). Make sure you install
   `base base-devel git sudo` plus a user account that has sudo.
2. **Get internet working temporarily** (any method — `iwctl`, ethernet, tether).
3. **Install paru** (AUR helper):
   ```bash
   sudo pacman -S --needed base-devel git
   git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si
   ```
4. **Clone this repo:**
   ```bash
   git clone git@github.com:USERNAME/dotfiles.git ~/dotfiles
   ```
5. **Run the installer:**
   ```bash
   cd ~/dotfiles && bash install.sh
   ```
   It installs packages, lays down user configs, and enables the user services.
6. **Run the root scripts** it tells you about, **in order** — these are kept
   separate because they need sudo with a password prompt and several are
   destructive (bootloader, PAM, networkd, SDDM, power):
   ```bash
   sudo bash scripts/wifi-fix.sh
   sudo bash scripts/fix-networkd-wlan0.sh
   sudo bash scripts/post-install-root.sh
   sudo bash scripts/set-sddm-astronaut.sh
   sudo bash scripts/setup-pretty-boot.sh
   sudo bash scripts/tune-power.sh
   ```
7. **Reboot.** Then log in, open kitty (`Super+Enter`), and run
   `caelestia shell -d` if the shell didn't come up on its own.

## Maintenance

After installing or removing packages, refresh the tracked lists and commit:

```bash
bash packages/refresh-package-lists.sh && git commit -am "Update package lists"
```

When you change a tracked config in `~/.config/...`, copy the change back into
`config/` here and commit it (the repo holds copies, not symlinks).

## What's NOT in this repo

Machine-specific state intentionally does **not** transfer, and rebuilding it is
part of first-boot setup:

- Saved WiFi PSKs in `/var/lib/iwd/` — reconnect to networks on the new machine.
- Browser profiles, application caches, runtime state (`**/state/`, history).
- Caelestia wallpapers (`caelestia/wallpaper*`) — large/personal, not tracked.
- Upstream Caelestia itself — it's pulled in fresh by the package install; this
  repo only carries the personal overrides under `config/`, not the upstream
  files in `~/.local/share/caelestia/`.
- Anything secret (`secrets/`, `.env*`, `*.pem`, `*.key`) — excluded by
  `.gitignore` as defense in depth.

## Full history

See [`setup-snapshot.md`](setup-snapshot.md) for the complete, narrated history
of how this system was built — every decision, script, and gotcha.
