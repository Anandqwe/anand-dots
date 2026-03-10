#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║   keybindings.sh — Rofi Keybinding Cheatsheet            ║
# ║   Beautiful, categorized, searchable reference menu.     ║
# ║   Press ESC or Super+Ctrl+K to close.                    ║
# ╚══════════════════════════════════════════════════════════╝

ROFI_THEME="$HOME/.config/rofi/keybindings.rasi"

# ── Formatting helpers ────────────────────────────────────
# Category header  (mauve, bold, icon prefix)
hdr() {
    printf "<span foreground='#cba6f7' font_weight='bold'> ▌  %s</span>\n" "$1"
}

# Visual divider between sections
div() {
    printf "<span foreground='#313244'>  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────</span>\n"
}

# Keybinding entry:
#   $1 = key combo  (padded to 30 chars — JetBrainsMono is monospace so spaces align)
#   $2 = description (plain text)
bind() {
    local key="$1" desc="$2"
    local padded
    padded=$(printf "%-30s" "$key")
    printf "<span foreground='#89b4fa' font_weight='bold'>%s</span>  <span foreground='#bac2de'>%s</span>\n" \
        "$padded" "$desc"
}

# ── Build full entry list ─────────────────────────────────

entries=(

    # ── App Launchers ──────────────────────────────────────
    "$(hdr "󰀻  App Launchers")"
    "$(bind "SUPER + Return"           "Open Terminal (Kitty)")"
    "$(bind "SUPER + D"                "App Launcher (rofi)")"
    "$(bind "SUPER + SHIFT + D"        "Window Switcher")"
    "$(bind "SUPER + B"                "Web Browser (Firefox)")"
    "$(bind "SUPER + E"                "File Manager (Nautilus)")"
    "$(bind "SUPER + X"                "Power Menu")"
    "$(bind "SUPER + SHIFT + V"        "Clipboard History")"

    "$(div)"

    # ── Window Management ──────────────────────────────────
    "$(hdr "󱂬  Window Management")"
    "$(bind "SUPER + Q"                "Close Active Window")"
    "$(bind "SUPER + F"                "Toggle Fullscreen")"
    "$(bind "SUPER + M"                "Maximize / Unmaximize")"
    "$(bind "SUPER + V"                "Toggle Floating Mode")"
    "$(bind "SUPER + P"                "Toggle Pseudo-Tiling")"
    "$(bind "SUPER + J"                "Toggle Split Direction")"
    "$(bind "SUPER + G"                "Toggle Window Group")"

    "$(div)"

    # ── Focus Navigation ───────────────────────────────────
    "$(hdr "  Focus Navigation")"
    "$(bind "SUPER + H  /  ←"          "Move Focus Left")"
    "$(bind "SUPER + L  /  →"          "Move Focus Right")"
    "$(bind "SUPER + K  /  ↑"          "Move Focus Up")"
    "$(bind "SUPER + SHIFT+J  /  ↓"    "Move Focus Down")"
    "$(bind "ALT + Tab"                "Cycle Through Open Windows")"

    "$(div)"

    # ── Move & Swap Windows ────────────────────────────────
    "$(hdr "󰆗  Move & Swap Windows")"
    "$(bind "SUPER + SHIFT + H"        "Move Window Left")"
    "$(bind "SUPER + SHIFT + L"        "Move Window Right")"
    "$(bind "SUPER + SHIFT + K"        "Move Window Up")"
    "$(bind "SUPER + CTRL + J"         "Move Window Down")"
    "$(bind "SUPER + ALT + ←"          "Swap Window Left")"
    "$(bind "SUPER + ALT + →"          "Swap Window Right")"
    "$(bind "SUPER + ALT + ↑"          "Swap Window Up")"
    "$(bind "SUPER + ALT + ↓"          "Swap Window Down")"
    "$(bind "SUPER + ALT + K"          "Swap Split")"

    "$(div)"

    # ── Resize ─────────────────────────────────────────────
    "$(hdr "󰙖  Resize Windows")"
    "$(bind "SUPER + SHIFT + →"        "Grow Window Right  (+100 px)")"
    "$(bind "SUPER + SHIFT + ←"        "Shrink Window Left  (−100 px)")"
    "$(bind "SUPER + SHIFT + ↓"        "Grow Window Down  (+100 px)")"
    "$(bind "SUPER + SHIFT + ↑"        "Shrink Window Up  (−100 px)")"
    "$(bind "SUPER + Right-click drag" "Drag-resize Floating Window")"

    "$(div)"

    # ── Workspaces ─────────────────────────────────────────
    "$(hdr "󰖳  Workspaces")"
    "$(bind "SUPER + 1 … 9,  0"        "Switch to Workspace 1 – 10")"
    "$(bind "SUPER + Tab"              "Next Workspace")"
    "$(bind "SUPER + SHIFT + Tab"      "Previous Workspace")"
    "$(bind "SUPER + CTRL + ↓"         "Switch to an Empty Workspace")"
    "$(bind "SUPER + Scroll ↑ / ↓"     "Scroll Through Workspaces")"
    "$(bind "SUPER + SHIFT + 1 … 0"    "Send Window to Workspace 1 – 10")"

    "$(div)"

    # ── Screenshots ────────────────────────────────────────
    "$(hdr "󰹑  Screenshots")"
    "$(bind "SUPER + SHIFT + S"        "Capture a Selected Area")"
    "$(bind "Print"                    "Capture the Full Screen")"
    "$(bind "SUPER + Print"            "Capture the Active Window")"

    "$(div)"

    # ── Wallpapers ─────────────────────────────────────────
    "$(hdr "󰸉  Wallpapers")"
    "$(bind "SUPER + CTRL + W"         "Open Wallpaper Manager (Waypaper)")"
    "$(bind "SUPER + SHIFT + W"        "Apply a Random Wallpaper")"

    "$(div)"

    # ── Display & Zoom ─────────────────────────────────────
    "$(hdr "󰹙  Display Zoom")"
    "$(bind "SUPER + SHIFT + Scroll ↑" "Zoom In  (+0.5×)")"
    "$(bind "SUPER + SHIFT + Scroll ↓" "Zoom Out (−0.5×)")"
    "$(bind "SUPER + SHIFT + Z"        "Reset Display Zoom to 1×")"

    "$(div)"

    # ── System & Actions ───────────────────────────────────
    "$(hdr "  System & Actions")"
    "$(bind "SUPER + CTRL + L"         "Lock Screen")"
    "$(bind "SUPER + CTRL + Q"         "Power Menu  (logout / reboot…)")"
    "$(bind "SUPER + CTRL + R"         "Reload Hyprland Config")"
    "$(bind "SUPER + CTRL + S"         "Open Settings GUI")"
    "$(bind "SUPER + CTRL + K"         "Show Keybinding Cheatsheet")"
    "$(bind "SUPER + CTRL + B"         "Toggle Waybar Visibility")"
    "$(bind "SUPER + SHIFT + B"        "Reload Waybar")"
    "$(bind "SUPER + SHIFT + A"        "Toggle Animations On / Off")"
    "$(bind "SUPER + ALT + G"          "Toggle Game Mode")"
    "$(bind "CTRL + Tab"               "Smart Window Switcher (focus)")"

    "$(div)"

    # ── Mouse Bindings ─────────────────────────────────────
    "$(hdr "󰍽  Mouse Bindings")"
    "$(bind "SUPER + Left-click drag"  "Move a Window")"
    "$(bind "SUPER + Right-click drag" "Resize a Window")"
    "$(bind "SUPER + Scroll ↑ / ↓"     "Switch Workspaces")"
    "$(bind "SUPER + SHIFT + Scroll"   "Zoom In / Out the Display")"

)

# ── Launch Rofi ───────────────────────────────────────────
printf '%s\n' "${entries[@]}" \
    | rofi -dmenu \
           -markup-rows \
           -i \
           -p "" \
           -selected-row 1 \
           -theme "$ROFI_THEME" \
           -mesg "<span foreground='#cba6f7' font_weight='bold'>󰌌  Keybinding Cheatsheet</span>   <span foreground='#6c7086'>─   ↑↓ to browse  ·  type to search  ·  Esc to close</span>" \
           > /dev/null 2>&1
