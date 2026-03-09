#!/usr/bin/env bash
# ── keybindings.sh ──────────────────────────────
# Display current keybindings in a wofi menu.
# Parses keybindings.conf for human-readable output.
# Usage: ./keybindings.sh

CONFIG="$HOME/.config/hypr/keybindings.conf"

if [[ ! -f "$CONFIG" ]]; then
    notify-send "Keybindings" "Config not found: $CONFIG"
    exit 1
fi

# Parse bind lines into readable format: KEY → ACTION
bindings=$(grep -E '^bind' "$CONFIG" \
    | sed 's/bindm\s*=/bind =/; s/binde\s*=/bind =/' \
    | sed 's/bind\s*=\s*//' \
    | awk -F',' '{
        mod = $1; key = $2; action = $3;
        for (i=4; i<=NF; i++) action = action "," $i;
        gsub(/^[ \t]+|[ \t]+$/, "", mod);
        gsub(/^[ \t]+|[ \t]+$/, "", key);
        gsub(/^[ \t]+|[ \t]+$/, "", action);
        if (mod != "") printf "%-20s → %s\n", mod " + " key, action;
    }')

echo "$bindings" | rofi -dmenu -p "Keybindings"
