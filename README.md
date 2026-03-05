# anand-dots

Hyprland dotfiles for Arch Linux. A lightweight, keyboard-driven, modular desktop environment.

![Hyprland](https://img.shields.io/badge/Hyprland-WM-blue?style=flat-square)
![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)
![Catppuccin](https://img.shields.io/badge/Theme-Catppuccin_Mocha-cba6f7?style=flat-square)

## Screenshots

> Add screenshots to `assets/screenshots/` and reference them here.

## Components

| Component | Tool |
|-----------|------|
| Window Manager | [Hyprland](https://hyprland.org) |
| Status Bar | [Waybar](https://github.com/Alexays/Waybar) |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| Launcher | [Wofi](https://hg.sr.ht/~scoopta/wofi) |
| Notifications | [Mako](https://github.com/emersion/mako) |
| Wallpaper | [swww](https://github.com/LGFae/swww) |
| Screenshots | grim + slurp |
| Clipboard | cliphist + wl-clipboard |

## Installation

```bash
git clone https://github.com/Anandqwe/anand-dots.git
cd anand-dots
chmod +x install.sh
./install.sh
```

The install script will:
1. Install required packages via pacman and yay
2. Backup existing configs
3. Symlink configs to `~/.config/`
4. Set Catppuccin Mocha as the default theme
5. Make scripts executable

After installation, log out and log back into Hyprland.

## Keybindings

### General
| Key | Action |
|-----|--------|
| `SUPER + Return` | Open terminal (kitty) |
| `SUPER + D` | Open launcher (wofi) |
| `SUPER + Q` | Close window |
| `SUPER + M` | Exit Hyprland |
| `SUPER + V` | Toggle floating |
| `SUPER + F` | Fullscreen |
| `SUPER + P` | Pseudo-tile |

### Navigation (vim-style)
| Key | Action |
|-----|--------|
| `SUPER + H/J/K/L` | Move focus left/down/up/right |
| `SUPER + SHIFT + H/J/K/L` | Move window left/down/up/right |
| `SUPER + CTRL + H/J/K/L` | Resize window |
| `SUPER + 1-9` | Switch workspace |
| `SUPER + SHIFT + 1-9` | Move window to workspace |

### Utilities
| Key | Action |
|-----|--------|
| `SUPER + SHIFT + S` | Screenshot (area) |
| `Print` | Screenshot (full) |
| `SUPER + X` | Power menu |
| `SUPER + SHIFT + V` | Clipboard history |

### Media
| Key | Action |
|-----|--------|
| `Volume Up/Down` | Adjust volume |
| `Volume Mute` | Toggle mute |
| `Brightness Up/Down` | Adjust brightness |
| `Play/Pause` | Toggle media |

## Theme Switching

Five themes are included:

- **catppuccin-mocha** (default)
- **gruvbox-dark**
- **tokyo-night**
- **nord**
- **dracula**

To switch themes:
```bash
# Replace <theme-name> with one of the above
ln -sf ~/anand-dots/themes/<theme-name>.conf ~/.config/hypr/theme.conf
hyprctl reload
```

> Note: Theme switching currently applies to Hyprland borders only. Waybar, kitty, wofi, and mako use hardcoded Catppuccin Mocha colors. Full theme switching across all components is planned for a future update.

## Structure

```
anand-dots/
├── README.md
├── install.sh
├── packages.txt
├── .gitignore
├── configs/
│   ├── hypr/
│   │   ├── hyprland.conf      # Main config (sources modules)
│   │   ├── monitors.conf      # Monitor setup
│   │   ├── keybindings.conf   # All keybindings
│   │   ├── rules.conf         # Window rules
│   │   └── animations.conf    # Animation settings
│   ├── waybar/
│   │   ├── config.jsonc       # Bar layout and modules
│   │   └── style.css          # Bar styling
│   ├── kitty/
│   │   └── kitty.conf         # Terminal config
│   ├── wofi/
│   │   ├── config             # Launcher settings
│   │   └── style.css          # Launcher styling
│   └── mako/
│       └── config             # Notification settings
├── scripts/
│   ├── reload.sh              # Reload environment
│   ├── powermenu.sh           # Power menu
│   ├── screenshot.sh          # Screenshot tool
│   ├── wallpaper.sh           # Wallpaper manager
│   └── clipboard.sh           # Clipboard history
├── themes/
│   ├── catppuccin-mocha.conf
│   ├── gruvbox-dark.conf
│   ├── tokyo-night.conf
│   ├── nord.conf
│   └── dracula.conf
└── assets/
    ├── wallpapers/
    └── screenshots/
```

## Customization

- **Monitor**: Edit `configs/hypr/monitors.conf`
- **Keybindings**: Edit `configs/hypr/keybindings.conf`
- **Window rules**: Edit `configs/hypr/rules.conf`
- **Animations**: Edit `configs/hypr/animations.conf`
- **Waybar modules**: Edit `configs/waybar/config.jsonc`

## License

MIT
