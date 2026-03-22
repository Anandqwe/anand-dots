/* ╔══════════════════════════════════════════════╗ */
/* ║      anand-dots — Waybar Style (ML4W)        ║ */
/* ║      Theme: {{theme_name}}                   ║ */
/* ╚══════════════════════════════════════════════╝ */

/* ── Global ─────────────────────────────────────── */
* {
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", "Font Awesome 6 Brands", FontAwesome, sans-serif;
    font-size: 14px;
    border: none;
    border-radius: 0px;
    min-height: 0;
}

window#waybar {
    background: transparent;
    color: {{text}};
}

/* ── Floating Pill Containers ───────────────────── */

.modules-left {
    background-color: alpha({{base}}, 0.82);
    border-radius: 14px;
    border: 1px solid alpha({{overlay2}}, 0.30);
    padding: 2px 4px;
    margin: 4px;
}

.modules-center {
    background-color: alpha({{base}}, 0.82);
    border-radius: 14px;
    border: 1px solid alpha({{overlay2}}, 0.30);
    padding: 2px 4px;
    margin: 4px;
}

.modules-right {
    background-color: alpha({{base}}, 0.82);
    border-radius: 14px;
    border: 1px solid alpha({{overlay2}}, 0.30);
    padding: 2px 4px;
    margin: 4px;
}

/* ── Module Labels (default) ────────────────────── */
label.module {
    font-size: 14px;
    color: {{text}};
    margin-left: 8px;
    margin-right: 8px;
}

/* ── Tooltip ────────────────────────────────────── */
tooltip {
    background-color: {{mantle}};
    border-radius: 12px;
    border: 1px solid alpha({{overlay2}}, 0.5);
    opacity: 0.92;
    padding: 8px;
}

tooltip label {
    color: {{text}};
}

/* ── Workspaces ─────────────────────────────────── */
#workspaces {
    padding: 4px 4px;
}

#workspaces button {
    color: {{subtext0}};
    border-radius: 8px;
    padding: 0px 8px;
    margin: 0px 2px;
    min-width: 28px;
    transition: all 0.3s ease-in-out;
    border: 1px solid transparent;
    background: transparent;
}

#workspaces button.active {
    background: alpha({{blue}}, 0.25);
    border: 1px solid alpha({{blue}}, 0.4);
    color: {{blue}};
    border-radius: 10px;
    min-width: 32px;
    box-shadow: inset 0 1px 2px alpha({{blue}}, 0.15);
}

#workspaces button:hover {
    background: alpha({{overlay2}}, 0.25);
    border-radius: 10px;
    color: {{text}};
}

#workspaces button.urgent {
    background: alpha({{red}}, 0.3);
    border: 1px solid alpha({{red}}, 0.5);
    color: {{red}};
}

/* ── Window Title ───────────────────────────────── */
#window {
    color: {{on_surface_variant}};
    font-weight: 400;
    padding: 0 10px;
    margin: 0 4px;
}

#window image {
    margin-right: 6px;
}

window#waybar.empty #window {
    background-color: transparent;
}

/* ── App Launcher ───────────────────────────────── */
#custom-appmenu {
    padding: 0 12px;
    margin: 0 4px;
    color: {{blue}};
    font-size: 18px;
    font-weight: bold;
}

#custom-appmenu:hover {
    color: {{text}};
}

/* ── Clock ──────────────────────────────────────── */
#clock {
    color: {{text}};
    font-weight: 600;
    padding: 0 10px;
    margin: 0 4px;
}

/* ── Battery ────────────────────────────────────── */
#battery {
    color: {{yellow}};
}

#battery.charging,
#battery.plugged {
    color: {{green}};
}

#battery.warning {
    color: {{peach}};
}

#battery.critical:not(.charging) {
    color: {{red}};
    animation: blink 1s linear infinite;
}

@keyframes blink {
    to {
        color: {{text}};
    }
}

/* ── Network ────────────────────────────────────── */
#network {
    color: {{teal}};
}

#network.disconnected {
    color: {{overlay2}};
}

/* ── Bluetooth ──────────────────────────────────── */
#bluetooth,
#bluetooth.on,
#bluetooth.connected {
    color: {{blue}};
}

#bluetooth.off {
    color: {{overlay2}};
}

/* ── Volume ─────────────────────────────────────── */
#pulseaudio {
    color: {{mauve}};
}

#pulseaudio.muted {
    color: {{overlay2}};
}

/* ── Hardware Group / Drawer ────────────────────── */
#disk,
#memory,
#cpu {
    margin: 0 6px;
    padding: 0 8px;
    color: {{subtext0}};
}

#custom-system {
    color: {{green}};
    margin: 0 6px;
    padding: 0 8px;
}

/* ── Clipboard ──────────────────────────────────── */
#custom-clipboard {
    color: {{text}};
}

#custom-clipboard:hover {
    color: {{teal}};
}

/* ── Tray ───────────────────────────────────────── */
#tray {
    padding: 0px 8px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
}

/* ── Power ──────────────────────────────────────── */
#custom-power {
    color: {{red}};
    padding: 0 12px;
}

#custom-power:hover {
    color: {{text}};
}

/* ── Updates (yellow/red badges) ────────────────── */
#custom-updates.yellow {
    border-radius: 8px;
    margin: 4px 0px 4px 4px;
    padding: 0px 6px;
    background-color: {{yellow}};
    color: {{crust}};
}

#custom-updates.red {
    border-radius: 8px;
    margin: 4px 0px 4px 4px;
    padding: 0px 6px;
    background-color: {{red}};
    color: {{crust}};
}
