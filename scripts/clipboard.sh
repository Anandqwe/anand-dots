#!/usr/bin/env bash
# ── clipboard.sh ────────────────────────────────────────────────
# Enhanced clipboard history manager: cliphist + rofi
#
# Modes:
#   (default)  — pick an entry and paste it        [SUPER+SHIFT+V]
#   --delete   — select an entry to remove         [SUPER+ALT+V]
#   --wipe     — clear the entire history          (no default bind)

MODE="${1:-pick}"
THEME="$HOME/.config/rofi/clipboard.rasi"

# ── Annotate image entries with icon + size ──────────────────────
annotate_entries() {
    while IFS=$'\t' read -r idx content; do
        if [[ "$content" == *"[[ binary data"* ]]; then
            size=$(grep -oP '[\d.]+ \w+iB' <<< "$content" | head -1)
            printf '%s\t󰋩  [image] %s\n' "$idx" "$size"
        else
            printf '%s\t%s\n' "$idx" "$content"
        fi
    done
}

# ── Re-fetch the original cliphist entry by numeric ID ───────────
get_entry_by_id() {
    cliphist list | awk -v id="$1" 'BEGIN{FS="\t"} $1==id {print; exit}'
}

# ── Pick: select entry and copy to clipboard ─────────────────────
pick_mode() {
    local selected id
    selected=$(cliphist list | annotate_entries \
        | rofi -dmenu -p "󰅋  Clipboard" -theme "$THEME" -display-columns 2)
    [[ -z "$selected" ]] && exit 0
    id=$(cut -f1 <<< "$selected")
    get_entry_by_id "$id" | cliphist decode | wl-copy
}

# ── Delete: select entry to remove from history ──────────────────
delete_mode() {
    local selected id
    selected=$(cliphist list | annotate_entries \
        | rofi -dmenu -p "󰅙  Delete Entry" -theme "$THEME" -display-columns 2)
    [[ -z "$selected" ]] && exit 0
    id=$(cut -f1 <<< "$selected")
    get_entry_by_id "$id" | cliphist delete
}

# ── Wipe: confirm then clear all history ─────────────────────────
wipe_mode() {
    local confirm
    confirm=$(printf 'yes\nno' \
        | rofi -dmenu -p "󰅙  Wipe all clipboard history?" -theme "$THEME")
    [[ "$confirm" != "yes" ]] && exit 0
    cliphist wipe
    notify-send -i edit-clear -t 2000 "Clipboard" "History cleared"
}

case "$MODE" in
    --delete) delete_mode ;;
    --wipe)   wipe_mode   ;;
    *)        pick_mode   ;;
esac
