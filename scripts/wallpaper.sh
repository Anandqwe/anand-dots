#!/usr/bin/env bash
# ── wallpaper.sh ────────────────────────────────
# Set wallpaper using swww.
# Usage: ./wallpaper.sh [path]
#   If no path given, picks random from ~/Pictures/Wallpapers/

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FALLBACK_DIR="$HOME/.config/hypr/wallpapers"
mkdir -p "$WALLPAPER_DIR"

if [[ -n "$1" ]]; then
    # Use provided path
    WALLPAPER="$1"
else
    # Pick a random wallpaper; check user dir first, then bundled fallback
    WALLPAPER=$(find "$WALLPAPER_DIR" "$FALLBACK_DIR" -type f \
        \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) \
        2>/dev/null | shuf -n 1)
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "No wallpaper found. Add images to $WALLPAPER_DIR"
    exit 1
fi

# Apply wallpaper with transition
swww img "$WALLPAPER" \
    --transition-type grow \
    --transition-duration 1 \
    --transition-fps 60

# Cache the wallpaper path for restore on login
CACHE_DIR="$HOME/.cache/anand-dots"
mkdir -p "$CACHE_DIR"
echo "$WALLPAPER" > "$CACHE_DIR/last-wallpaper"

# Keep a symlink for rofi imagebox background
ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper"

# Apply dynamic colors from wallpaper (matugen)
MATUGEN_SCRIPT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../scripts/matugen-apply.sh"
[[ ! -f "$MATUGEN_SCRIPT" ]] && MATUGEN_SCRIPT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/matugen-apply.sh"
if [[ -f "$MATUGEN_SCRIPT" ]] && command -v matugen &>/dev/null; then
    bash "$MATUGEN_SCRIPT" "$WALLPAPER" &
fi

notify-send "Wallpaper set" "$(basename "$WALLPAPER")"
