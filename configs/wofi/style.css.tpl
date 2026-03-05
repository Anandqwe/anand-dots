/* ╔══════════════════════════════════════════════╗ */
/* ║          anand-dots — Wofi Style             ║ */
/* ║          Theme: {{theme_name}}               */
/* ╚══════════════════════════════════════════════╝ */

/* ── Window ─────────────────────────────────────── */
window {
    margin: 0;
    border: 2px solid {{blue}};
    border-radius: 12px;
    background-color: {{base}};
    font-family: "JetBrainsMono Nerd Font", sans-serif;
    font-size: 13px;
}

/* ── Input Field ────────────────────────────────── */
#input {
    margin: 8px;
    padding: 10px 16px;
    border: none;
    border-radius: 8px;
    background-color: {{mantle}};
    color: {{text}};
    font-size: 14px;
}

/* ── Inner Container ────────────────────────────── */
#inner-box {
    margin: 0 8px 8px 8px;
    border: none;
    background-color: transparent;
}

/* ── Outer Container ────────────────────────────── */
#outer-box {
    margin: 0;
    border: none;
    background-color: transparent;
}

/* ── Scroll ─────────────────────────────────────── */
#scroll {
    margin: 0;
    border: none;
}

/* ── List Items ─────────────────────────────────── */
#entry {
    padding: 8px 12px;
    border-radius: 8px;
    color: {{text}};
    transition: all 0.2s ease;
}

#entry:selected {
    background-color: {{surface0}};
    color: {{blue}};
    outline: none;
}

/* ── Item Text ──────────────────────────────────── */
#text {
    margin: 0 8px;
    color: inherit;
}

#text:selected {
    color: {{blue}};
}

/* ── Item Image ─────────────────────────────────── */
#img {
    margin-right: 8px;
}
