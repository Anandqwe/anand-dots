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
| Launcher | [Rofi](https://davatorium.github.io/rofi/) |
| Notifications | [Mako](https://github.com/emersion/mako) |
| Lock Screen | [hyprlock](https://github.com/hyprwm/hyprlock) |
| Idle Daemon | [hypridle](https://github.com/hyprwm/hypridle) |
| Wallpaper | [swww](https://github.com/LGFae/swww) |
| Screenshots | grim + slurp |
| Clipboard | cliphist + wl-clipboard |
| File Manager | [Nautilus](https://gitlab.gnome.org/GNOME/nautilus) |
| Browser | Firefox |
| System Info | [fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **Settings GUI** | GTK4 / Libadwaita (built-in) |

## Installation

```bash
git clone https://github.com/Anandqwe/anand-dots.git
cd anand-dots
chmod +x install.sh
./install.sh
```

The install script will:
1. Install required packages via pacman and yay
2. Backup existing configs (saved as `*.bak.TIMESTAMP`)
3. Symlink configs to `~/.config/`
4. Prompt you to pick a theme (default: catppuccin-mocha)
5. Make scripts and the settings app executable

After installation, log out and log back into Hyprland.

> **Requirements:** `python-gobject`, `libadwaita`, `gtk4` — needed for the Settings GUI. These are installed automatically by the install script.

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
| `SUPER + D` | Open launcher (rofi) |
| `SUPER + SHIFT + D` | Window switcher (rofi) |
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
| `SUPER + SHIFT + T` | Switch theme (rofi picker) |
| `SUPER + CTRL + S` | Open Settings GUI |
| `SUPER + SHIFT + mouse scroll` | Zoom in/out |
| `SUPER + SHIFT + Z` | Reset zoom |

### Media
| Key | Action |
|-----|--------|
| `Volume Up/Down` | Adjust volume |
| `Volume Mute` | Toggle mute |
| `Brightness Up/Down` | Adjust brightness |
| `Play/Pause` | Toggle media |

## Settings GUI

A GTK4 / Libadwaita settings application lets you tweak the entire configuration visually — no config file editing needed.

**Launch:** `SUPER + CTRL + S` or:
```bash
~/.config/hypr/scripts/settings.sh
```

### Pages
| Page | What you can configure |
|------|------------------------|
| General | Gaps, borders, layout, cursor size, tearing |
| Appearance | Corner radius, opacity, blur, shadows |
| Animations | Master toggle, per-category speed |
| Theme | Switch between the 5 built-in color themes |
| Monitor | Resolution, refresh rate, display scale |
| Input | Keyboard layout, mouse sensitivity, touchpad |
| Idle & Lock | Dim / lock / DPMS / suspend timeouts |
| Terminal | Font, opacity, padding, cursor, scrollback |
| Notifications | Duration, position, width, border, rounding |

Every setting has a description explaining what it does and what happens at high/low values. Click **Apply** to save all changes and auto-reload all services.

## Theme Switching

Five high-quality themes are included, with **full theme switching** across all components:

- **catppuccin-mocha** (default)
- **gruvbox-dark**
- **tokyo-night**
- **nord**
- **dracula**

### GUI Picker
Press `SUPER + SHIFT + T` to open a rofi picker listing all available themes. Select one to apply it instantly.

### Command Line
```bash
~/.config/hypr/scripts/theme.sh catppuccin-mocha
~/.config/hypr/scripts/theme.sh dracula
~/.config/hypr/scripts/theme.sh gruvbox-dark
~/.config/hypr/scripts/theme.sh nord
~/.config/hypr/scripts/theme.sh tokyo-night
```

### How It Works
The theme switcher generates and applies colors to all components:
- **Hyprland** — window borders and lock screen
- **Waybar** — status bar
- **Kitty** — terminal
- **Rofi** — application launcher
- **Mako** — notifications

Each theme is defined once in `themes/`, and the theme switcher generates all app configs from templates automatically.

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
│   ├── rofi/
│   │   ├── config.rasi         # Launcher layout and behavior
│   │   ├── colors.rasi         # Color palette
│   │   └── wallpaper.rasi      # Dynamic wallpaper background
│   ├── mako/
│   │   └── config             # Notification settings
│   ├── fastfetch/
│   │   └── config.jsonc       # System info display
│   ├── ohmyposh/
│   │   └── zen.toml           # Shell prompt theme
│   └── zsh/                   # Zsh shell config
├── settings/
│   └── main.py                # GTK4 settings GUI (SUPER+CTRL+S)
├── scripts/
│   ├── reload.sh              # Reload environment
│   ├── powermenu.sh           # Power menu
│   ├── screenshot.sh          # Screenshot tool
│   ├── settings.sh            # Launch settings GUI
│   ├── wallpaper.sh           # Wallpaper picker
│   ├── wallpaper-restore.sh   # Restore last wallpaper
│   ├── clipboard.sh           # Clipboard history
│   ├── focus.sh               # Focus helper
│   ├── gamemode.sh            # Toggle game mode
│   ├── keybindings.sh         # Show keybindings cheatsheet
│   ├── matugen-apply.sh       # Apply dynamic wallpaper colors
│   ├── theme.sh               # Full theme switcher
│   ├── toggle-animations.sh   # Toggle animations on/off
│   └── toggle-waybar.sh       # Toggle Waybar visibility
├── themes/
│   ├── catppuccin-mocha.conf  # Theme color definitions
│   ├── gruvbox-dark.conf
│   ├── tokyo-night.conf
│   ├── nord.conf
│   └── dracula.conf
├── configs/hypr/
│   ├── hyprlock.conf.tpl      # Hyprlock template
│   └── theme.conf             # Active theme symlink
├── configs/waybar/
│   └── style.css.tpl          # Waybar CSS template
├── configs/kitty/
│   └── kitty.conf.tpl         # Kitty config template
├── configs/rofi/
	└── colors.rasi.tpl        # Rofi color theme template
├── configs/mako/
│   └── config.tpl             # Mako config template
└── assets/
    ├── wallpapers/
    └── screenshots/
```

## Customization

> **Tip:** Most settings can be changed via the **Settings GUI** (`SUPER+CTRL+S`) without editing any files.

- **Everything visual**: Use the Settings GUI — gaps, blur, shadows, opacity, animations, theme, monitor, idle timeouts, terminal, notifications
- **Monitor**: Edit `configs/hypr/monitors.conf`
- **Keybindings**: Edit `configs/hypr/keybindings.conf`
- **Window rules**: Edit `configs/hypr/rules.conf`
- **Animations**: Edit `configs/hypr/animations.conf`
- **Lock screen**: Edit `configs/hypr/hyprlock.conf`
- **Idle/suspend policy**: Edit `configs/hypr/hypridle.conf`
- **Waybar modules**: Edit `configs/waybar/config.jsonc`
- **Waybar style**: Edit `configs/waybar/style.css.tpl` (template) or `configs/waybar/style.css` (generated)
- **Kitty terminal**: Edit `configs/kitty/kitty.conf.tpl` (template) or `configs/kitty/kitty.conf` (generated)
- **Shell prompt**: Edit `configs/ohmyposh/zen.toml`
- **System info**: Edit `configs/fastfetch/config.jsonc`
- **Zsh config**: Edit `configs/zsh/`

## License

MIT
