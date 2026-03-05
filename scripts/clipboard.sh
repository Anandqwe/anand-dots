#!/usr/bin/env bash
# ── clipboard.sh ────────────────────────────────
# Clipboard history viewer using cliphist + wofi.
# Usage: ./clipboard.sh

cliphist list | wofi --dmenu --prompt "Clipboard" | cliphist decode | wl-copy
