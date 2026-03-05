#!/usr/bin/env bash
# ── wallpaper-restore.sh ────────────────────────
# Restore the last-used wallpaper on login.
# Saves and restores from a cache file.
# Usage: ./wallpaper-restore.sh

CACHE_FILE="$HOME/.cache/anand-dots/last-wallpaper"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FALLBACK_DIR="$HOME/.config/hypr/wallpapers"

mkdir -p "$(dirname "$CACHE_FILE")"

if [[ -f "$CACHE_FILE" ]]; then
    WALLPAPER=$(cat "$CACHE_FILE")
    if [[ -f "$WALLPAPER" ]]; then
        swww img "$WALLPAPER" \
            --transition-type grow \
            --transition-duration 1 \
            --transition-fps 60
        exit 0
    fi
fi

# No cache or file missing — pick random
~/.config/hypr/scripts/wallpaper.sh
