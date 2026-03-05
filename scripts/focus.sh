#!/usr/bin/env bash
# ── focus.sh ────────────────────────────────────
# Window switcher: list open windows and focus selected.
# Usage: ./focus.sh

selected=$(hyprctl clients -j | jq -r '.[] | "\(.address) | \(.class) — \(.title)"' \
    | wofi --dmenu --prompt "Windows" --width 600 --height 400 \
    | awk -F' \\| ' '{print $1}')

if [[ -n "$selected" ]]; then
    hyprctl dispatch focuswindow address:"$selected"
fi
