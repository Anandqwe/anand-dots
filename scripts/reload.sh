#!/usr/bin/env bash
# ── reload.sh ───────────────────────────────────
# Reload Hyprland config and restart Waybar.
# Usage: ./reload.sh

# Reload Hyprland
hyprctl reload

# Restart Waybar
killall waybar 2>/dev/null
waybar &disown

echo "Environment reloaded"
