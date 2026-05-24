#!/usr/bin/env bash
# set-sddm-astronaut.sh — point SDDM at sddm-astronaut-theme and select the
# "black_hole" background variant.
#
# STAGED, NOT RUN. Run manually as root, ideally from a TTY:
#     sudo bash ~/set-sddm-astronaut.sh
# It does NOT restart sddm — you do that yourself after saving work, because a
# restart kills the running graphical session.
#
# Generated 2026-05-24.
set -euo pipefail

VARIANT="black_hole"
THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
META="${THEME_DIR}/metadata.desktop"
VARIANT_CONF="${THEME_DIR}/Themes/${VARIANT}.conf"
CONF_DIR="/etc/sddm.conf.d"
THEME_CONF="${CONF_DIR}/theme.conf"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root:  sudo bash $0" >&2
    exit 1
fi

# --- sanity checks ----------------------------------------------------------
[[ -f "${META}" ]] || { echo "ERROR: ${META} not found — is the theme installed?" >&2; exit 1; }
[[ -f "${VARIANT_CONF}" ]] || { echo "ERROR: variant '${VARIANT}' (${VARIANT_CONF}) not found." >&2; exit 1; }

# --- 1. select the theme in SDDM -------------------------------------------
mkdir -p "${CONF_DIR}"
if [[ -e "${THEME_CONF}" ]]; then
    cp -a "${THEME_CONF}" "${THEME_CONF}.bak-${STAMP}"
    echo "Backed up existing ${THEME_CONF} -> ${THEME_CONF}.bak-${STAMP}"
fi
cat > "${THEME_CONF}" <<'EOF'
[Theme]
Current=sddm-astronaut-theme
EOF
echo "Wrote ${THEME_CONF}"

# --- 2. select the background variant --------------------------------------
# This theme picks its variant via the ConfigFile= line in metadata.desktop.
# metadata.desktop is package-owned, so a theme upgrade can reset it to the
# default (astronaut.conf) — just re-run this script if that happens.
cp -a "${META}" "${META}.bak-${STAMP}"
echo "Backed up ${META} -> ${META}.bak-${STAMP}"
sed -i "s|^ConfigFile=.*|ConfigFile=Themes/${VARIANT}.conf|" "${META}"
echo -n "metadata.desktop now: "; grep '^ConfigFile=' "${META}"

echo
echo "Theme set. Test with: sudo systemctl restart sddm  (WARNING: this kills your session — only run from a TTY or after saving work)."
