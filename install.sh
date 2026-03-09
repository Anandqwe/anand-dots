#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║       anand-dots — Install Script             ║
# ║       Hyprland Dotfiles for Arch Linux        ║
# ╚══════════════════════════════════════════════╝
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d_%H%M%S)"

# ── Colors ──────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── User Input Functions ────────────────────
prompt_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -p "$(echo -e ${BLUE}${prompt}${NC}) (y/n): " response
        case "$response" in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

select_theme() {
    local themes=()
    local i=1

    # Gather available themes
    while IFS= read -r theme_file; do
        local theme_name="${theme_file%.conf}"
        themes+=("$theme_name")
    done < <(find "$DOTFILES_DIR/themes" -maxdepth 1 -name "*.conf" -type f | sort | xargs -I {} basename {})

    if [[ ${#themes[@]} -eq 0 ]]; then
        warn "No themes found. Using default: catppuccin-mocha"
        echo "catppuccin-mocha"
        return
    fi

    echo ""
    echo -e "${BLUE}Available themes:${NC}"
    for theme in "${themes[@]}"; do
        echo "  $i) $theme"
        ((i++))
    done
    echo ""

    local choice
    while true; do
        read -p "$(echo -e ${BLUE}Select theme \(1-${#themes[@]}\):${NC}) " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#themes[@]} ]]; then
            echo "${themes[$((choice-1))]}"
            return
        else
            echo "Invalid selection. Please enter a number between 1 and ${#themes[@]}."
        fi
    done
}

# ── Check Arch Linux ───────────────────────────
if [[ ! -f /etc/arch-release ]]; then
    error "This script is designed for Arch Linux."
fi

info "Starting anand-dots installation..."

# ── Parse packages.txt ─────────────────────────
parse_packages() {
    local section=""
    local pacman_pkgs=()
    local aur_pkgs=()

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        if [[ "$line" == "[pacman]" ]]; then
            section="pacman"
        elif [[ "$line" == "[aur]" ]]; then
            section="aur"
        elif [[ "$section" == "pacman" ]]; then
            pacman_pkgs+=("$line")
        elif [[ "$section" == "aur" ]]; then
            aur_pkgs+=("$line")
        fi
    done < "$DOTFILES_DIR/packages.txt"

    echo "PACMAN:${pacman_pkgs[*]}"
    echo "AUR:${aur_pkgs[*]}"
}

# ── Install Packages ──────────────────────────
install_packages() {
    info "Parsing package list..."

    local pacman_pkgs=()
    local aur_pkgs=()

    while IFS= read -r line; do
        if [[ "$line" == PACMAN:* ]]; then
            read -ra pacman_pkgs <<< "${line#PACMAN:}"
        elif [[ "$line" == AUR:* ]]; then
            read -ra aur_pkgs <<< "${line#AUR:}"
        fi
    done < <(parse_packages)

    if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
        info "Installing pacman packages..."
        sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"
        success "Pacman packages installed."
    fi

    if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
        if command -v yay &>/dev/null; then
            info "Installing AUR packages with yay..."
            yay -S --needed --noconfirm "${aur_pkgs[@]}"
            success "AUR packages installed."
        else
            warn "yay not found. Skipping AUR packages: ${aur_pkgs[*]}"
            warn "Install yay first: https://github.com/Jguer/yay"
        fi
    fi
}

# ── Backup Existing Configs ───────────────────
backup_config() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        warn "Backing up $target → ${target}${BACKUP_SUFFIX}"
        mv "$target" "${target}${BACKUP_SUFFIX}"
    elif [[ -L "$target" ]]; then
        # Remove existing symlink
        rm "$target"
    fi
}

# ── Create Symlinks ───────────────────────────
link_configs() {
    info "Linking configuration files..."

    # List of config directories to symlink
    local configs=("hypr" "waybar" "kitty" "rofi" "mako" "wlogout" "waypaper")

    for config in "${configs[@]}"; do
        local source="$DOTFILES_DIR/configs/$config"
        local target="$CONFIG_DIR/$config"

        backup_config "$target"
        ln -sf "$source" "$target"
        success "Linked $config → $target"
    done
}

# ── Link Theme ────────────────────────────────
link_theme() {
    local theme="${1:-catppuccin-mocha}"
    local theme_file="$DOTFILES_DIR/themes/${theme}.conf"
    local target="$CONFIG_DIR/hypr/theme.conf"

    if [[ -f "$theme_file" ]]; then
        ln -sf "$theme_file" "$target"
        success "Theme set: $theme"
    else
        warn "Theme file not found: $theme_file"
        warn "Available themes:"
        ls "$DOTFILES_DIR/themes/"
    fi
}

# ── Link Scripts ──────────────────────────────
link_scripts() {
    info "Setting up scripts..."
    local scripts_target="$CONFIG_DIR/hypr/scripts"

    # Remove existing scripts link/dir
    if [[ -L "$scripts_target" ]]; then
        rm "$scripts_target"
    elif [[ -d "$scripts_target" ]]; then
        mv "$scripts_target" "${scripts_target}${BACKUP_SUFFIX}"
    fi

    ln -sf "$DOTFILES_DIR/scripts" "$scripts_target"

    # Make all scripts executable
    chmod +x "$DOTFILES_DIR/scripts/"*.sh
    success "Scripts linked and made executable."
}

# ── Create Directories ────────────────────────
create_directories() {
    info "Creating directories..."
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/.cache/anand-dots"          # wallpaper restore cache

    # Copy bundled wallpapers (if any) to ~/Pictures/Wallpapers
    local bundled="$DOTFILES_DIR/assets/wallpapers"
    if [[ -d "$bundled" ]]; then
        find "$bundled" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) \
            -exec cp -n {} "$HOME/Pictures/Wallpapers/" \;
        info "Bundled wallpapers copied to ~/Pictures/Wallpapers"
    fi

    success "Directories created."
}

# ── Main ──────────────────────────────────────
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         anand-dots installer             ║${NC}"
    echo -e "${BLUE}║    Hyprland Dotfiles for Arch Linux      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # ── Ask for package installation ────────
    if prompt_yes_no "[1/5] Install packages (pacman + AUR)?"; then
        install_packages
    else
        info "Skipping package installation."
    fi

    echo ""

    # ── Ask for directory creation ─────────
    if prompt_yes_no "[2/5] Create directories and copy wallpapers?"; then
        create_directories
    else
        info "Skipping directory creation."
    fi

    echo ""

    # ── Ask for config linking ────────────
    if prompt_yes_no "[3/5] Link configuration files?"; then
        link_configs
    else
        info "Skipping config linking."
    fi

    echo ""

    # ── Ask for script linking ────────────
    if prompt_yes_no "[4/5] Link and make scripts executable?"; then
        link_scripts
    else
        info "Skipping script linking."
    fi

    echo ""

    # ── Ask for theme selection ──────────
    if prompt_yes_no "[5/5] Select and apply a theme?"; then
        local selected_theme=$(select_theme)
        link_theme "$selected_theme"
    else
        info "Skipping theme setup. You can set it later with: ln -sf themes/{theme}.conf ~/.config/hypr/theme.conf"
    fi

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Installation complete!             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    info "Log out and log back in to Hyprland to apply changes."
    info "Or if already in Hyprland, run: hyprctl reload"
    echo ""
    info "What's included:"
    echo "  • Hyprland  — window manager with MD3 animations"
    echo "  • Waybar    — status bar with window title"
    echo "  • Hyprlock  — lock screen (SUPER+CTRL+L)"
    echo "  • Hypridle  — auto-lock + dpms + suspend"
    echo "  • Rofi      — app launcher (SUPER+D, SUPER+SHIFT+D for windows)"
    echo "  • Mako      — notifications"
    echo "  • swww      — wallpaper engine (SUPER+SHIFT+W)"
    echo ""
    warn "Optional: install 'bibata-cursor-theme' (AUR) for the Bibata cursor."
    warn "Optional: install 'thunar' and 'firefox' if not already present."
    echo ""
}

main "$@"
