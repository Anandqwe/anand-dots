#!/usr/bin/env bash
# ── clipboard.sh ────────────────────────────────
# Clipboard history viewer using cliphist + rofi.
# Usage: ./clipboard.sh

cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy
