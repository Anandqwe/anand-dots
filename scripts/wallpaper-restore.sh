#!/usr/bin/env bash
# ── wallpaper-restore.sh ────────────────────────
# Restore the last-used wallpaper on login.
# Saves and restores from a cache file.
# Usage: ./wallpaper-restore.sh

CACHE_FILE="$HOME/.cache/anand-dots/last-wallpaper"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FALLBACK_DIR="$HOME/.config/hypr/wallpapers"
SCRIPT_REAL="$(realpath "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$(dirname "$SCRIPT_REAL")"
DOTFILES_DIR="$(dirname "$SCRIPTS_DIR")"

mkdir -p "$(dirname "$CACHE_FILE")"

# Support both legacy swww and renamed awww binaries.
if command -v swww &>/dev/null; then
    WALL_BIN="swww"
elif command -v awww &>/dev/null; then
    WALL_BIN="awww"
else
    echo "Wallpaper backend not found. Install swww or awww."
    exit 1
fi

if [[ -f "$CACHE_FILE" ]]; then
    WALLPAPER=$(cat "$CACHE_FILE")
    if [[ -f "$WALLPAPER" ]]; then
        "$WALL_BIN" img "$WALLPAPER" \
            --transition-type grow \
            --transition-duration 1 \
            --transition-fps 60
        # Restore symlink for rofi
        if command -v git &>/dev/null && git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
            if git -C "$DOTFILES_DIR" ls-files --error-unmatch "configs/hypr/current_wallpaper" &>/dev/null; then
                git -C "$DOTFILES_DIR" update-index --skip-worktree "configs/hypr/current_wallpaper" &>/dev/null || true
            fi
        fi
        ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper"
        # Re-apply dynamic colors so they match the restored wallpaper
        SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
        if [[ -f "$SCRIPT_DIR/matugen-apply.sh" ]] && command -v matugen &>/dev/null; then
            ANAND_DOTS_UPDATE_WAYBAR_STYLE=0 bash "$SCRIPT_DIR/matugen-apply.sh" "$WALLPAPER" &
        fi
        exit 0
    fi
fi

# No cache or file missing — pick random
bash "$SCRIPTS_DIR/wallpaper.sh"
