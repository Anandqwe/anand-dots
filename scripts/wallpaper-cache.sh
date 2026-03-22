#!/usr/bin/env bash
# ── wallpaper-cache.sh ───────────────────────────────────
# Post-command called by waypaper after setting a wallpaper.
# waypaper handles the swww call; this script just updates
# the cache and sends a notification.

WALLPAPER="$1"
[[ -z "$WALLPAPER" ]] && exit 0

SCRIPT_REAL="$(realpath "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$(dirname "$SCRIPT_REAL")"
DOTFILES_DIR="$(dirname "$SCRIPTS_DIR")"

CACHE_DIR="$HOME/.cache/anand-dots"
mkdir -p "$CACHE_DIR"

# Save path for restore-on-login
echo "$WALLPAPER" > "$CACHE_DIR/last-wallpaper"

# Symlink for other tools that need current wallpaper path
if command -v git &>/dev/null && git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    if git -C "$DOTFILES_DIR" ls-files --error-unmatch "configs/hypr/current_wallpaper" &>/dev/null; then
        git -C "$DOTFILES_DIR" update-index --skip-worktree "configs/hypr/current_wallpaper" &>/dev/null || true
    fi
fi
ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper"

# Apply dynamic colors from wallpaper (matugen)
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"  
if [[ -f "$SCRIPT_DIR/matugen-apply.sh" ]] && command -v matugen &>/dev/null; then
    ANAND_DOTS_UPDATE_WAYBAR_STYLE=0 bash "$SCRIPT_DIR/matugen-apply.sh" "$WALLPAPER" &
fi

notify-send -i preferences-desktop-wallpaper-symbolic \
    "Wallpaper" "$(basename "$WALLPAPER")"
