#!/usr/bin/env bash
# ── powermenu.sh ────────────────────────────────
# Power menu using wlogout (wayland-native).
# Usage: ./powermenu.sh

CONFIG_DIR="$HOME/.config/wlogout"

wlogout \
    --layout          "$CONFIG_DIR/layout" \
    --css             "$CONFIG_DIR/style.css" \
    --buttons-per-row 5 \
    --column-spacing  30 \
    --row-spacing     30 \
    --margin-top      320 \
    --margin-bottom   320 \
    --margin-left     130 \
    --margin-right    130
