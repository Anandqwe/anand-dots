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
| Shell | zsh |
| Prompt | [Oh My Posh](https://ohmyposh.dev) |
| Launcher | [Wofi](https://hg.sr.ht/~scoopta/wofi) |
| Notifications | [Mako](https://github.com/emersion/mako) |
| Lock Screen | [hyprlock](https://github.com/hyprwm/hyprlock) |
| Idle Daemon | [hypridle](https://github.com/hyprwm/hypridle) |
| Wallpaper | [swww](https://github.com/LGFae/swww) |
| Screenshots | grim + slurp |
| Clipboard | cliphist + wl-clipboard |
| File Manager | [Nautilus](https://gitlab.gnome.org/GNOME/nautilus) |
| Browser | Firefox |
| System Info | [fastfetch](https://github.com/fastfetch-cli/fastfetch) |

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

### Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

The uninstall script removes symlinks and optionally restores backed-up configs.

## Keybindings

### General
| Key | Action |
|-----|--------|
| `SUPER + Return` | Open terminal (kitty) |
| `SUPER + D` | Open launcher (wofi) |
| `SUPER + B` | Open browser (firefox) |
| `SUPER + E` | Open file manager (nautilus) |
| `SUPER + Q` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + M` | Maximize |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Pseudo-tile |
| `SUPER + J` | Toggle split |
| `SUPER + G` | Toggle window group |
| `SUPER + X` | Power menu |
| `SUPER + SHIFT + V` | Clipboard history |

### Navigation (vim-style)
| Key | Action |
|-----|--------|
| `SUPER + H/K/L` | Move focus left/up/right |
| `SUPER + Arrow keys` | Move focus (arrow-style) |
| `SUPER + SHIFT + H/K/L` | Move window left/up/right |
| `SUPER + CTRL + J` | Move window down |
| `SUPER + ALT + Arrows` | Swap windows |
| `ALT + Tab` | Cycle windows |
| `SUPER + 1-9 / 0` | Switch to workspace 1-10 |
| `SUPER + SHIFT + 1-9 / 0` | Move window to workspace 1-10 |
| `SUPER + Tab` | Next workspace |
| `SUPER + SHIFT + Tab` | Previous workspace |
| `SUPER + CTRL + Down` | Open empty workspace |

### Resize
| Key | Action |
|-----|--------|
| `SUPER + SHIFT + Arrow keys` | Resize active window |

### Screenshots
| Key | Action |
|-----|--------|
| `SUPER + SHIFT + S` | Screenshot (area) |
| `Print` | Screenshot (full screen) |
| `SUPER + Print` | Screenshot (active window) |

### Wallpaper & Display
| Key | Action |
|-----|--------|
| `SUPER + SHIFT + W` | Open wallpaper picker |
| `SUPER + SHIFT + mouse scroll` | Zoom in/out |
| `SUPER + SHIFT + Z` | Reset zoom |

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
├── uninstall.sh
├── packages.txt
├── .gitignore
├── configs/
│   ├── hypr/
│   │   ├── hyprland.conf      # Main config (sources modules)
│   │   ├── monitors.conf      # Monitor setup
│   │   ├── keybindings.conf   # All keybindings
│   │   ├── rules.conf         # Window rules
│   │   ├── animations.conf    # Animation settings
│   │   ├── theme.conf         # Active theme variables
│   │   ├── hypridle.conf      # Idle/suspend policy
│   │   ├── hyprlock.conf      # Lock screen config
│   │   └── scripts/           # Hypr-specific helper scripts
│   ├── waybar/
│   │   ├── config.jsonc       # Bar layout and modules
│   │   └── style.css          # Bar styling
│   ├── kitty/
│   │   └── kitty.conf         # Terminal config
│   ├── wofi/
│   │   ├── config             # Launcher settings
│   │   └── style.css          # Launcher styling
│   ├── mako/
│   │   └── config             # Notification settings
│   ├── fastfetch/
│   │   └── config.jsonc       # System info display
│   ├── ohmyposh/
│   │   └── zen.toml           # Shell prompt theme
│   └── zsh/                   # Zsh shell config
├── scripts/
│   ├── reload.sh              # Reload environment
│   ├── powermenu.sh           # Power menu
│   ├── screenshot.sh          # Screenshot tool
│   ├── wallpaper.sh           # Wallpaper picker
│   ├── wallpaper-restore.sh   # Restore last wallpaper
│   ├── clipboard.sh           # Clipboard history
│   ├── focus.sh               # Focus helper
│   ├── gamemode.sh            # Toggle game mode
│   ├── keybindings.sh         # Show keybindings cheatsheet
│   ├── toggle-animations.sh   # Toggle animations on/off
│   └── toggle-waybar.sh       # Toggle Waybar visibility
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
- **Lock screen**: Edit `configs/hypr/hyprlock.conf`
- **Idle/suspend policy**: Edit `configs/hypr/hypridle.conf`
- **Waybar modules**: Edit `configs/waybar/config.jsonc`
- **Waybar style**: Edit `configs/waybar/style.css`
- **Shell prompt**: Edit `configs/ohmyposh/zen.toml`
- **System info**: Edit `configs/fastfetch/config.jsonc`
- **Zsh config**: Edit `configs/zsh/`

## License

MIT
