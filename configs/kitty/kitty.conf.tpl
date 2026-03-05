# ╔══════════════════════════════════════════════╗
# ║         anand-dots — Kitty Config             ║
# ║         Theme: {{theme_name}}                 ║
# ╚══════════════════════════════════════════════╝

# ── Shell ───────────────────────────────────────
shell /usr/bin/zsh

# ── Font ────────────────────────────────────────
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

# ── Window ──────────────────────────────────────
window_padding_width 12
background_opacity   0.5
confirm_os_window_close 0

# ── Cursor ──────────────────────────────────────
cursor_shape beam
cursor_blink_interval 0.5

# ── Scrollback ──────────────────────────────────
scrollback_lines 10000

# ── Bell ────────────────────────────────────────
enable_audio_bell no

# ── Tab Bar ─────────────────────────────────────
tab_bar_style    powerline
tab_powerline_style slanted

# ── URL Handling ────────────────────────────────
url_style curly
detect_urls yes

# ── Color Scheme: {{theme_name}} ─────────────────

# Special
foreground           {{text}}
background           {{base}}
selection_foreground  {{base}}
selection_background  {{rosewater}}
cursor               {{rosewater}}
cursor_text_color    {{base}}
url_color            {{blue}}

# Black
color0  {{surface1}}
color8  {{surface2}}

# Red
color1  {{red}}
color9  {{red}}

# Green
color2  {{green}}
color10 {{green}}

# Yellow
color3  {{yellow}}
color11 {{yellow}}

# Blue
color4  {{blue}}
color12 {{blue}}

# Magenta
color5  {{pink}}
color13 {{pink}}

# Cyan
color6  {{teal}}
color14 {{teal}}

# White
color7  {{subtext1}}
color15 {{subtext0}}

# Tab bar colors
active_tab_foreground   {{crust}}
active_tab_background   {{mauve}}
inactive_tab_foreground {{text}}
inactive_tab_background {{mantle}}
tab_bar_background      {{crust}}
