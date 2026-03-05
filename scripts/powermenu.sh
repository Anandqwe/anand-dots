#!/usr/bin/env bash
# ── powermenu.sh ────────────────────────────────
# Power menu using wofi.
# Usage: ./powermenu.sh

options="  Lock\n  Logout\n  Suspend\n  Reboot\n  Shutdown"

selected=$(echo -e "$options" | wofi --dmenu --prompt "Power" --width 250 --height 260 --lines 5)

case "$selected" in
    *Lock)
        swaylock ;;
    *Logout)
        hyprctl dispatch exit ;;
    *Suspend)
        systemctl suspend ;;
    *Reboot)
        systemctl reboot ;;
    *Shutdown)
        systemctl poweroff ;;
esac
