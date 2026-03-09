#!/usr/bin/env bash
# ── powermenu.sh ────────────────────────────────
# Power menu using rofi.
# Usage: ./powermenu.sh

options="  Lock\n  Logout\n  Suspend\n  Reboot\n  Shutdown"

selected=$(echo -e "$options" | rofi -dmenu -p "Power")

case "$selected" in
    *Lock)
        hyprlock ;;
    *Logout)
        hyprctl dispatch exit ;;
    *Suspend)
        systemctl suspend ;;
    *Reboot)
        systemctl reboot ;;
    *Shutdown)
        systemctl poweroff ;;
esac
