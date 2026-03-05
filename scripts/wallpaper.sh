#!/usr/bin/env bash
# ── wallpaper.sh ────────────────────────────────
# Set wallpaper using swww.
# Usage: ./wallpaper.sh [path]
#   If no path given, picks random from ~/Pictures/Wallpapers/

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"

if [[ -n "$1" ]]; then
    # Use provided path
    WALLPAPER="$1"
else
    # Pick a random wallpaper
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
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

notify-send "Wallpaper set" "$(basename "$WALLPAPER")"
