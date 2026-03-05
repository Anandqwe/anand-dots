/* ╔══════════════════════════════════════════════╗ */
/* ║         anand-dots — Waybar Style            ║ */
/* ║         Theme: {{theme_name}}                */
/* ╚══════════════════════════════════════════════╝ */

/* ── Color Reference ────────────────────────────── */
/* base:     {{base}}   mantle:   {{mantle}}         */
/* crust:    {{crust}}  text:     {{text}}           */
/* subtext0: {{subtext0}} surface0: {{surface0}}     */
/* surface1: {{surface1}} blue:   {{blue}}           */
/* mauve:    {{mauve}}  green:    {{green}}          */
/* peach:    {{peach}}  yellow:   {{yellow}}         */
/* red:      {{red}}    teal:     {{teal}}           */

/* ── Global ─────────────────────────────────────── */
* {
    font-family: "JetBrainsMono Nerd Font", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: {{base}};
    color: {{text}};
}

/* ── Tooltip ────────────────────────────────────── */
tooltip {
    background-color: {{mantle}};
    border: 1px solid {{surface1}};
    border-radius: 8px;
    color: {{text}};
}

/* ── Module Containers ──────────────────────────── */
#workspaces,
#window,
#clock,
#cpu,
#memory,
#battery,
#network,
#bluetooth,
#pulseaudio,
#tray,
#custom-power {
    padding: 0 12px;
    margin: 4px 2px;
    border-radius: 8px;
    background-color: {{surface0}};
    transition: all 0.2s ease;
}

/* ── Active Window Title ────────────────────────── */
#window {
    color: {{text}};
    font-weight: bold;
}

/* ── Workspaces ─────────────────────────────────── */
#workspaces {
    padding: 0 4px;
}

#workspaces button {
    padding: 0 8px;
    color: {{subtext0}};
    border: none;
    border-radius: 6px;
    background: transparent;
    transition: all 0.2s ease;
}

#workspaces button:hover {
    background-color: {{surface1}};
    color: {{text}};
}

#workspaces button.active {
    background-color: {{blue}};
    color: {{crust}};
    font-weight: bold;
}

#workspaces button.urgent {
    background-color: {{red}};
    color: {{crust}};
}

/* ── Clock ──────────────────────────────────────── */
#clock {
    color: {{text}};
    font-weight: bold;
}

/* ── CPU ────────────────────────────────────────── */
#cpu {
    color: {{green}};
}

/* ── Memory ─────────────────────────────────────── */
#memory {
    color: {{peach}};
}

/* ── Battery ────────────────────────────────────── */
#battery {
    color: {{yellow}};
}

#battery.warning {
    color: {{peach}};
}

#battery.critical {
    color: {{red}};
    animation: blink 1s linear infinite;
}

@keyframes blink {
    to {
        color: {{text}};
    }
}

/* ── Bluetooth ──────────────────────────────────── */
#bluetooth {
    color: {{blue}};
}

#bluetooth.connected {
    color: {{sky}};
}

#bluetooth.disabled,
#bluetooth.off {
    color: {{subtext0}};
}

/* ── Network ────────────────────────────────────── */
#network {
    color: {{teal}};
}

#network.disconnected {
    color: {{subtext0}};
}

/* ── Volume ─────────────────────────────────────── */
#pulseaudio {
    color: {{mauve}};
}

#pulseaudio.muted {
    color: {{subtext0}};
}

/* ── System Tray ────────────────────────────────── */
#tray {
    padding: 0 8px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
}

/* ── Power Button ───────────────────────────────── */
#custom-power {
    color: {{red}};
    padding: 0 10px;
}

#custom-power:hover {
    background-color: {{red}};
    color: {{crust}};
}
