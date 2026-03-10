#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║     anand-dots — Settings Launcher            ║
# ║  Checks deps and launches the settings GUI    ║
# ╚══════════════════════════════════════════════╝

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SETTINGS_DIR="$(dirname "$SCRIPT_DIR")/settings"

# ── Check dependencies ──────────────────────────
check_deps() {
    if ! command -v python3 &>/dev/null; then
        notify-send "Settings" "python3 is required but not installed." -u critical
        exit 1
    fi

    python3 -c "
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw
" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        notify-send "Settings" "Missing: python-gobject, gtk4, libadwaita\nInstall: sudo pacman -S python-gobject gtk4 libadwaita" -u critical
        exit 1
    fi
}

check_deps
exec python3 "$SETTINGS_DIR/main.py" "$@"
