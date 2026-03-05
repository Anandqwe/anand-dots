#!/usr/bin/env bash
# ── toggle-animations.sh ────────────────────────
# Toggle Hyprland animations on/off.
# Usage: ./toggle-animations.sh

CURRENT=$(hyprctl getoption animations:enabled | grep "int:" | awk '{print $2}')

if [[ "$CURRENT" == "1" ]]; then
    hyprctl keyword animations:enabled false
    notify-send "Animations" "Disabled"
else
    hyprctl keyword animations:enabled true
    notify-send "Animations" "Enabled"
fi
