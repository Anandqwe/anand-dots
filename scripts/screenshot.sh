#!/usr/bin/env bash
# ── screenshot.sh ───────────────────────────────
# Screenshot utility using grim + slurp.
# Usage: ./screenshot.sh [full|area|window]

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FILENAME="$SCREENSHOT_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

case "${1:-area}" in
    full)
        grim "$FILENAME"
        ;;
    area)
        grim -g "$(slurp)" "$FILENAME"
        ;;
    window)
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$FILENAME"
        ;;
    *)
        echo "Usage: $0 [full|area|window]"
        exit 1
        ;;
esac

# Check if screenshot was taken successfully
if [[ -f "$FILENAME" ]]; then
    # Copy to clipboard
    wl-copy < "$FILENAME"
    # Send notification
    notify-send "Screenshot saved" "$FILENAME" -i "$FILENAME"
fi
