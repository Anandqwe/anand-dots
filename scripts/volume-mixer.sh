#!/usr/bin/env bash
# Open the best available audio mixer GUI for PipeWire/PulseAudio.
# Preference order:
# 1) pwvucontrol (PipeWire-native)
# 2) pavucontrol (widely supported)
# 3) pavucontrol-qt

if command -v pwvucontrol >/dev/null 2>&1; then
    exec pwvucontrol
fi

if command -v pavucontrol >/dev/null 2>&1; then
    exec pavucontrol
fi

if command -v pavucontrol-qt >/dev/null 2>&1; then
    exec pavucontrol-qt
fi

notify-send -u normal "Audio mixer not found" "Install pavucontrol (recommended) or pwvucontrol."
exit 1
