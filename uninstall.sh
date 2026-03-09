#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║       anand-dots — Uninstall Script           ║
# ║       Hyprland Dotfiles for Arch Linux        ║
# ╚══════════════════════════════════════════════╝
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

# ── Colors ──────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

prompt_yes_no() {
    local msg="$1"
    local default="${2:-n}"
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    read -rp "$(echo -e "${YELLOW}[?]${NC} ${msg} ${prompt}: ")" answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ── Check Arch Linux ───────────────────────────
if [[ ! -f /etc/arch-release ]]; then
    error "This script is designed for Arch Linux."
fi

# ── Restore or Remove a Config Entry ──────────
remove_config() {
    local target="$1"
    local name="$(basename "$target")"

    if [[ -L "$target" ]]; then
        rm "$target"
        success "Removed symlink: $target"

        # Restore most-recent backup if one exists
        local latest_bak
        latest_bak=$(find "$(dirname "$target")" -maxdepth 1 -name "${name}.bak.*" 2>/dev/null \
            | sort | tail -n1)
        if [[ -n "$latest_bak" ]]; then
            mv "$latest_bak" "$target"
            success "Restored backup: $latest_bak → $target"
        fi
    elif [[ -e "$target" ]]; then
        warn "$target exists but is not a symlink — skipping."
    else
        info "$target not found — nothing to remove."
    fi
}

# ── Remove Config Symlinks ─────────────────────
remove_configs() {
    info "Removing configuration symlinks..."
    local configs=("hypr" "waybar" "kitty" "rofi" "mako")
    for config in "${configs[@]}"; do
        remove_config "$CONFIG_DIR/$config"
    done
}

# ── Remove Scripts Symlink ─────────────────────
remove_scripts() {
    local scripts_target="$CONFIG_DIR/hypr/scripts"
    info "Removing scripts symlink..."
    if [[ -L "$scripts_target" ]]; then
        rm "$scripts_target"
        success "Removed symlink: $scripts_target"
    elif [[ -e "$scripts_target" ]]; then
        warn "$scripts_target is not a symlink — skipping."
    else
        info "$scripts_target not found — nothing to remove."
    fi
}

# ── Parse packages.txt ─────────────────────────
parse_packages() {
    local section=""
    local pacman_pkgs=()
    local aur_pkgs=()

    while IFS= read -r line; do
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

# ── Remove Packages ───────────────────────────
remove_packages() {
    local pacman_pkgs=()
    local aur_pkgs=()

    while IFS= read -r line; do
        if [[ "$line" == PACMAN:* ]]; then
            read -ra pacman_pkgs <<< "${line#PACMAN:}"
        elif [[ "$line" == AUR:* ]]; then
            read -ra aur_pkgs <<< "${line#AUR:}"
        fi
    done < <(parse_packages)

    local all_pkgs=("${pacman_pkgs[@]}" "${aur_pkgs[@]}")
    if [[ ${#all_pkgs[@]} -eq 0 ]]; then
        warn "No packages found in packages.txt."
        return
    fi

    info "The following packages will be removed:"
    printf '  %s\n' "${all_pkgs[@]}"
    echo ""

    if prompt_yes_no "Remove these packages?"; then
        sudo pacman -Rns --noconfirm "${all_pkgs[@]}" 2>/dev/null || \
            warn "Some packages may not have been installed — continuing."
        success "Packages removed."
    else
        info "Skipping package removal."
    fi
}

# ── Remove Directories ────────────────────────
remove_directories() {
    local dirs=(
        "$HOME/Pictures/Screenshots"
        "$HOME/Pictures/Wallpapers"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            if prompt_yes_no "Remove $dir and its contents?"; then
                rm -rf "$dir"
                success "Removed $dir"
            else
                info "Skipping $dir"
            fi
        fi
    done
}

# ── Main ──────────────────────────────────────
main() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║         anand-dots uninstaller           ║${NC}"
    echo -e "${RED}║    Hyprland Dotfiles for Arch Linux      ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo ""

    warn "This will remove all anand-dots symlinks from ~/.config."
    warn "Backed-up configs (*.bak.*) will be restored automatically."
    echo ""

    if ! prompt_yes_no "Continue with uninstall?" "n"; then
        info "Uninstall cancelled."
        exit 0
    fi
    echo ""

    remove_configs
    remove_scripts

    echo ""
    if prompt_yes_no "Remove installed packages listed in packages.txt?"; then
        remove_packages
    else
        info "Skipping package removal."
    fi

    echo ""
    remove_directories

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Uninstall complete!               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    info "You may need to log out and back in to apply the changes."
    echo ""
}

main "$@"
