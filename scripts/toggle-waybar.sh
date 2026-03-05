#!/usr/bin/env bash
# ── toggle-waybar.sh ────────────────────────────
# Toggle Waybar visibility.
# Usage: ./toggle-waybar.sh

if pgrep -x waybar > /dev/null; then
    killall waybar
else
    waybar &disown
fi
