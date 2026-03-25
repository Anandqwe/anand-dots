#!/usr/bin/env bash
# ── wallpaper-manager.sh ───────────────────────
# Launch waypaper with backend compatibility.
# Some distros/package variants rename swww -> awww.

set -e

LOCAL_BIN="$HOME/.local/bin"

ensure_swww_compat() {
    if command -v swww >/dev/null 2>&1; then
        return 0
    fi

    if ! command -v awww >/dev/null 2>&1; then
        notify-send "Wallpaper" "Install swww (or awww) to use Waypaper."
        return 1
    fi

    mkdir -p "$LOCAL_BIN"

    # Create local compatibility shims so tools expecting swww continue to work.
    if [[ ! -e "$LOCAL_BIN/swww" ]]; then
        ln -s "$(command -v awww)" "$LOCAL_BIN/swww"
    fi

    if command -v awww-daemon >/dev/null 2>&1 && [[ ! -e "$LOCAL_BIN/swww-daemon" ]]; then
        ln -s "$(command -v awww-daemon)" "$LOCAL_BIN/swww-daemon"
    fi

    export PATH="$LOCAL_BIN:$PATH"

    if ! command -v swww >/dev/null 2>&1; then
        notify-send "Wallpaper" "Could not create swww compatibility shim."
        return 1
    fi

    return 0
}

start_daemon_if_needed() {
    if command -v swww-daemon >/dev/null 2>&1; then
        if ! pgrep -x swww-daemon >/dev/null 2>&1; then
            swww-daemon >/dev/null 2>&1 &
            sleep 0.2
        fi
        return 0
    fi

    if command -v awww-daemon >/dev/null 2>&1; then
        if ! pgrep -x awww-daemon >/dev/null 2>&1; then
            awww-daemon >/dev/null 2>&1 &
            sleep 0.2
        fi
    fi
}

ensure_swww_compat || exit 1
start_daemon_if_needed

exec env PATH="$LOCAL_BIN:$PATH" waypaper
