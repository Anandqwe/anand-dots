#!/usr/bin/env bash
# ── gamemode.sh ─────────────────────────────────
# Toggle game mode: disables animations, blur,
# borders, and gaps for maximum performance.
# Usage: ./gamemode.sh

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

if [ "$HYPRGAMEMODE" = 1 ]; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 0;\
        keyword decoration:rounding 0"
    notify-send "Game Mode" "Enabled — performance optimized"
else
    hyprctl --batch "\
        keyword animations:enabled 1;\
        keyword decoration:shadow:enabled 1;\
        keyword decoration:blur:enabled 1;\
        keyword general:gaps_in 4;\
        keyword general:gaps_out 8;\
        keyword general:border_size 2;\
        keyword decoration:rounding 10"
    notify-send "Game Mode" "Disabled — effects restored"
fi
