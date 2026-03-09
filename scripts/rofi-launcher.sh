#!/usr/bin/env bash
# ── rofi-launcher.sh ────────────────────────────
# Launch rofi with current wallpaper injected into
# the imagebox background (binnewbs-style layout)

ROFI_DIR="$HOME/.config/rofi"
WALLPAPER=$(cat "$HOME/.cache/anand-dots/last-wallpaper" 2>/dev/null)
MODI="${1:-drun}"

# Write dynamic wallpaper.rasi before launching
if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    printf 'imagebox { background-image: url("%s", height); }\n' "$WALLPAPER" > "$ROFI_DIR/wallpaper.rasi"
else
    printf 'imagebox { background-color: #11111b; }\n' > "$ROFI_DIR/wallpaper.rasi"
fi

exec rofi -show "$MODI"
