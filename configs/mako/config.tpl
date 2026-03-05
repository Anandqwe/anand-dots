# ╔══════════════════════════════════════════════╗
# ║         anand-dots — Mako Config              ║
# ║         Theme: {{theme_name}}                 ║
# ╚══════════════════════════════════════════════╝

# ── Font ────────────────────────────────────────
font=JetBrainsMono Nerd Font 11

# ── Colors ──────────────────────────────────────
background-color={{base}}ee
text-color={{text}}
border-color={{blue}}

# ── Layout ──────────────────────────────────────
width=350
height=100
margin=8
padding=12
border-size=2
border-radius=8

# ── Behavior ────────────────────────────────────
default-timeout=5000
max-visible=3
anchor=top-right
layer=overlay

# ── Icons ───────────────────────────────────────
icons=1
max-icon-size=48

# ── Urgency: Low ───────────────────────────────
[urgency=low]
border-color={{surface0}}

# ── Urgency: Normal ────────────────────────────
[urgency=normal]
border-color={{blue}}

# ── Urgency: Critical ──────────────────────────
[urgency=critical]
border-color={{red}}
default-timeout=0
