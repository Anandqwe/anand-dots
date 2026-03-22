#!/usr/bin/env bash
# ── wallpaper-cache.sh ───────────────────────────────────
# Post-command called by waypaper after setting a wallpaper.
# waypaper handles the swww call; this script just updates
# the cache and sends a notification.

WALLPAPER="$1"
[[ -z "$WALLPAPER" ]] && exit 0

CACHE_DIR="$HOME/.cache/anand-dots"
mkdir -p "$CACHE_DIR"

# Save path for restore-on-login
echo "$WALLPAPER" > "$CACHE_DIR/last-wallpaper"

# Symlink for other tools that need current wallpaper path
ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper"

# Apply dynamic colors from wallpaper (matugen)
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"  
if [[ -f "$SCRIPT_DIR/matugen-apply.sh" ]] && command -v matugen &>/dev/null; then
    ANAND_DOTS_UPDATE_WAYBAR_STYLE=0 bash "$SCRIPT_DIR/matugen-apply.sh" "$WALLPAPER" &
fi

notify-send -i preferences-desktop-wallpaper-symbolic \
    "Wallpaper" "$(basename "$WALLPAPER")"
