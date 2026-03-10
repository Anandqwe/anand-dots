#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║       anand-dots — Install Script             ║
# ║       Hyprland Dotfiles for Arch Linux        ║
# ╚══════════════════════════════════════════════╝

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$DOTFILES_DIR/install-logs"
LOG="$LOG_DIR/install-$(date +%Y%m%d_%H%M%S).log"
AUR_HELPER=""   # resolved at runtime

# ── Colors ──────────────────────────────────────
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BLUE='' CYAN='' BOLD='' NC=''
fi

info()    { echo -e "${BLUE}[INFO]${NC}    $*" | tee -a "$LOG"; }
success() { echo -e "${GREEN}[OK]${NC}      $*" | tee -a "$LOG"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*" | tee -a "$LOG"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" | tee -a "$LOG"; exit 1; }
step()    { echo -e "\n${CYAN}${BOLD}══ $* ══${NC}" | tee -a "$LOG"; }

# ── Logging Setup ───────────────────────────────
mkdir -p "$LOG_DIR"
echo "anand-dots install log — $(date)" > "$LOG"
echo "Dotfiles: $DOTFILES_DIR" >> "$LOG"
echo "--------------------------------------" >> "$LOG"

# ── Guard Rails ─────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Do NOT run this script as root." >&2
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    echo -e "${RED}[ERROR]${NC} This script is designed for Arch Linux only." >&2
    exit 1
fi

# ── CLI Flags ───────────────────────────────────
# Usage: install.sh [-p] [-d] [-c] [-s] [-t] [-a]
#   -p  install packages       -d  create directories
#   -c  link configs            -s  link scripts
#   -t  apply theme             -a  all steps (default if no flags)
_do_packages=0 _do_dirs=0 _do_configs=0 _do_scripts=0 _do_theme=0

while getopts "pdcstah" opt; do
    case "$opt" in
        p) _do_packages=1 ;;
        d) _do_dirs=1 ;;
        c) _do_configs=1 ;;
        s) _do_scripts=1 ;;
        t) _do_theme=1 ;;
        a) _do_packages=1; _do_dirs=1; _do_configs=1; _do_scripts=1; _do_theme=1 ;;
        h)
            echo "Usage: $0 [-p] [-d] [-c] [-s] [-t] [-a]"
            echo "  -p  Install packages (pacman + AUR)"
            echo "  -d  Create directories and copy wallpapers"
            echo "  -c  Link configuration files"
            echo "  -s  Link scripts and make them executable"
            echo "  -t  Select and apply a theme"
            echo "  -a  All steps (non-interactive)"
            echo "  (no flags)  Interactive mode — prompts for each step"
            exit 0 ;;
        *) echo "Unknown option. Run '$0 -h' for help." ; exit 1 ;;
    esac
done

INTERACTIVE=0
if [[ $(( _do_packages + _do_dirs + _do_configs + _do_scripts + _do_theme )) -eq 0 ]]; then
    INTERACTIVE=1
fi

# ── Input Helpers ────────────────────────────────
prompt_yes_no() {
    # $1 = question, $2 = default (y|n, default n)
    local prompt="$1" default="${2:-n}" answer
    local hint=$([[ "$default" == "y" ]] && echo "[Y/n]" || echo "[y/N]")
    while true; do
        read -rp "$(echo -e "${BLUE}[?]${NC} ${prompt} ${hint}: ")" answer
        answer="${answer:-$default}"
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) echo "  Please answer y or n." ;;
        esac
    done
}

ask_step() {
    # Returns 0 (do it) if flag set OR interactive and user said yes
    local flag="$1" prompt="$2"
    if [[ $INTERACTIVE -eq 1 ]]; then
        prompt_yes_no "$prompt"
    else
        [[ "$flag" -eq 1 ]]
    fi
}

select_theme() {
    local themes=() i=1
    while IFS= read -r f; do
        themes+=("$(basename "${f%.conf}")")
    done < <(find "$DOTFILES_DIR/themes" -maxdepth 1 -name "*.conf" -type f | sort)

    if [[ ${#themes[@]} -eq 0 ]]; then
        warn "No themes found in themes/. Defaulting to catppuccin-mocha."
        echo "catppuccin-mocha"; return
    fi

    echo "" >&2
    echo -e "${CYAN}Available themes:${NC}" >&2
    for t in "${themes[@]}"; do
        printf "  %d) %s\n" "$i" "$t" >&2
        ((i++))
    done
    echo "" >&2

    local choice
    while true; do
        read -rp "$(echo -e "${BLUE}[?]${NC} Select theme (1-${#themes[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#themes[@]} )); then
            echo "${themes[$((choice-1))]}"; return
        fi
        echo "  Invalid — enter a number between 1 and ${#themes[@]}." >&2
    done
}

# ── Dependency Checks ────────────────────────────
check_deps() {
    step "Checking dependencies"

    # Ensure base-devel is present
    if ! pacman -Q base-devel &>/dev/null; then
        info "Installing base-devel..."
        sudo pacman -S --needed --noconfirm base-devel | tee -a "$LOG" \
            || error "Failed to install base-devel."
    else
        success "base-devel is present."
    fi

    # Resolve AUR helper (prefer existing install; prefer yay)
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
        success "AUR helper: yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
        success "AUR helper: paru"
    else
        warn "No AUR helper found (yay / paru)."
        echo "" 
        echo -e "  ${CYAN}Select an AUR helper to install:${NC}"
        echo "    1) yay"
        echo "    2) paru"
        local pick
        while true; do
            read -rp "$(echo -e "${BLUE}[?]${NC} Choice (1/2): ")" pick
            case "$pick" in
                1) AUR_HELPER="yay"; break ;;
                2) AUR_HELPER="paru"; break ;;
                *) echo "  Enter 1 or 2." ;;
            esac
        done
        _install_aur_helper "$AUR_HELPER"
    fi

    # Detect NVIDIA
    if lspci 2>/dev/null | grep -qi nvidia; then
        warn "NVIDIA GPU detected — if you have issues, ensure nvidia-dkms is installed."
        echo "NVIDIA detected" >> "$LOG"
    fi
}

_install_aur_helper() {
    local helper="$1"
    info "Cloning and building $helper..."
    local tmp
    tmp=$(mktemp -d)
    git clone "https://aur.archlinux.org/${helper}.git" "$tmp/$helper" 2>&1 | tee -a "$LOG" \
        || error "Failed to clone $helper."
    (cd "$tmp/$helper" && makepkg -si --noconfirm 2>&1 | tee -a "$LOG") \
        || error "Failed to build $helper."
    rm -rf "$tmp"
    success "$helper installed."
}

# ── Parse packages.txt ─────────────────────────
_parse_packages() {
    local section="" line
    _PACMAN_PKGS=()
    _AUR_PKGS=()

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        case "$line" in
            "[pacman]") section="pacman" ;;
            "[aur]")    section="aur" ;;
            *)
                [[ "$section" == "pacman" ]] && _PACMAN_PKGS+=("$line")
                [[ "$section" == "aur"    ]] && _AUR_PKGS+=("$line")
                ;;
        esac
    done < "$DOTFILES_DIR/packages.txt"
}

# ── Install Packages ──────────────────────────
install_packages() {
    step "Installing packages"
    _parse_packages

    if [[ ${#_PACMAN_PKGS[@]} -gt 0 ]]; then
        info "Installing ${#_PACMAN_PKGS[@]} pacman packages..."
        sudo pacman -S --needed --noconfirm "${_PACMAN_PKGS[@]}" 2>&1 | tee -a "$LOG" \
            && success "Pacman packages installed." \
            || warn "Some pacman packages may have failed — check $LOG"
    fi

    if [[ ${#_AUR_PKGS[@]} -gt 0 ]]; then
        if [[ -z "$AUR_HELPER" ]]; then
            warn "No AUR helper available — skipping AUR packages."
            warn "AUR packages needed: ${_AUR_PKGS[*]}"
        else
            info "Installing ${#_AUR_PKGS[@]} AUR packages with $AUR_HELPER..."
            "$AUR_HELPER" -S --needed --noconfirm "${_AUR_PKGS[@]}" 2>&1 | tee -a "$LOG" \
                && success "AUR packages installed." \
                || warn "Some AUR packages may have failed — check $LOG"
        fi
    fi
}

# ── Verify Essential Packages ─────────────────
verify_packages() {
    step "Verifying essential packages"
    local essentials=(hyprland waybar kitty rofi mako swww hyprlock hypridle)
    local missing=()
    for pkg in "${essentials[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            success "$pkg ✓"
        else
            warn "$pkg — NOT found"
            missing+=("$pkg")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing packages: ${missing[*]}"
        warn "Run 'sudo pacman -S ${missing[*]}' or re-run with -p"
    else
        success "All essential packages are installed."
    fi
}

# ── Backup Helper ─────────────────────────────
_backup() {
    local target="$1"
    if [[ -L "$target" ]]; then
        rm "$target"
    elif [[ -e "$target" ]]; then
        warn "Backing up $(basename "$target") → $(basename "$target")${BACKUP_SUFFIX}"
        mv "$target" "${target}${BACKUP_SUFFIX}"
    fi
}

# ── Link Configs ──────────────────────────────
link_configs() {
    step "Linking configuration files"
    local configs=(hypr waybar kitty rofi mako wlogout waypaper fastfetch ohmyposh)

    for cfg in "${configs[@]}"; do
        local src="$DOTFILES_DIR/configs/$cfg"
        local dst="$CONFIG_DIR/$cfg"
        [[ ! -d "$src" ]] && { warn "Source missing: $src — skipping."; continue; }
        _backup "$dst"
        ln -sf "$src" "$dst"
        success "Linked  $cfg"
    done
}

# ── Link Theme ────────────────────────────────
link_theme() {
    local theme="${1:-catppuccin-mocha}"
    local src="$DOTFILES_DIR/themes/${theme}.conf"
    local dst="$CONFIG_DIR/hypr/theme.conf"

    if [[ -f "$src" ]]; then
        ln -sf "$src" "$dst"
        success "Theme applied: $theme"
    else
        warn "Theme file not found: ${theme}.conf"
        warn "Available themes:"; ls "$DOTFILES_DIR/themes/" | tee -a "$LOG"
    fi
}

# ── Link Scripts ──────────────────────────────
link_scripts() {
    step "Setting up scripts"
    local dst="$CONFIG_DIR/hypr/scripts"

    _backup "$dst"
    ln -sf "$DOTFILES_DIR/scripts" "$dst"
    chmod +x "$DOTFILES_DIR/scripts/"*.sh
    [[ -f "$DOTFILES_DIR/settings/main.py" ]] && chmod +x "$DOTFILES_DIR/settings/main.py"
    success "Scripts linked and made executable."
}

# ── Create Directories ────────────────────────
create_directories() {
    step "Creating directories"
    local dirs=("$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers" "$HOME/.cache/anand-dots")
    for d in "${dirs[@]}"; do
        mkdir -p "$d" && success "Ensured $d"
    done

    local bundled="$DOTFILES_DIR/assets/wallpapers"
    if [[ -d "$bundled" ]]; then
        find "$bundled" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) \
            -exec cp -n {} "$HOME/Pictures/Wallpapers/" \;
        info "Bundled wallpapers copied → ~/Pictures/Wallpapers"
    fi
}

# ── Enable System Services ────────────────────
enable_services() {
    step "Enabling system services"
    local services=(bluetooth)   # add more if needed e.g. sddm

    for svc in "${services[@]}"; do
        if systemctl list-unit-files "${svc}.service" &>/dev/null; then
            if ! systemctl is-enabled --quiet "${svc}.service" 2>/dev/null; then
                sudo systemctl enable --now "${svc}.service" 2>&1 | tee -a "$LOG" \
                    && success "Enabled: $svc" || warn "Could not enable $svc"
            else
                success "$svc already enabled."
            fi
        else
            info "$svc service not found — skipping."
        fi
    done
}

# ── Print Summary ─────────────────────────────
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Installation complete!             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    info "Install log saved → $LOG"
    echo ""
    echo -e "${CYAN}Keybinds to get started:${NC}"
    echo "  SUPER+D           App launcher (Rofi)"
    echo "  SUPER+SHIFT+D     Window switcher"
    echo "  SUPER+CTRL+L      Lock screen (Hyprlock)"
    echo "  SUPER+SHIFT+W     Wallpaper picker"
    echo "  SUPER+CTRL+S      Settings GUI"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  • Log out and select Hyprland from your display manager, or"
    echo "  • If already in Hyprland: hyprctl reload"
    echo "  • Place wallpapers in ~/Pictures/Wallpapers/"
    echo ""
}

# ── Reboot Prompt ─────────────────────────────
prompt_reboot() {
    echo ""
    if prompt_yes_no "Reboot now to apply all changes?" "n"; then
        info "Rebooting..."
        systemctl reboot
    else
        info "Skipping reboot. Remember to log out/in or reboot when ready."
    fi
}

# ── Main ──────────────────────────────────────
main() {
    clear
    echo ""
    echo -e "${BLUE}${BOLD}"
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │         a n a n d - d o t s             │"
    echo "  │    Hyprland Dotfiles for Arch Linux      │"
    echo "  └─────────────────────────────────────────┘"
    echo -e "${NC}"
    echo -e "  Log: ${CYAN}$LOG${NC}"
    echo ""

    # ── Pre-flight ──────────────────────────
    check_deps

    echo ""

    # ── Packages ────────────────────────────
    if ask_step "$_do_packages" "[1/5] Install packages (pacman + AUR)?"; then
        install_packages
    else
        info "Skipping package installation."
    fi

    echo ""

    # ── Directories ─────────────────────────
    if ask_step "$_do_dirs" "[2/5] Create directories and copy wallpapers?"; then
        create_directories
    else
        info "Skipping directory creation."
    fi

    echo ""

    # ── Configs ─────────────────────────────
    if ask_step "$_do_configs" "[3/5] Link configuration files?"; then
        link_configs
    else
        info "Skipping config linking."
    fi

    echo ""

    # ── Scripts ─────────────────────────────
    if ask_step "$_do_scripts" "[4/5] Link and make scripts executable?"; then
        link_scripts
    else
        info "Skipping script linking."
    fi

    echo ""

    # ── Theme ───────────────────────────────
    if ask_step "$_do_theme" "[5/5] Select and apply a theme?"; then
        local chosen_theme
        chosen_theme=$(select_theme)
        link_theme "$chosen_theme"
    else
        info "Skipping theme setup."
        info "Apply later: ln -sf \$DOTFILES/themes/<name>.conf ~/.config/hypr/theme.conf"
    fi

    echo ""

    # ── Services ────────────────────────────
    if ask_step "0" "Enable system services (e.g. bluetooth)?"; then
        enable_services
    else
        info "Skipping service setup."
    fi

    echo ""

    # ── Verify ──────────────────────────────
    verify_packages

    # ── Done ────────────────────────────────
    print_summary
    prompt_reboot
}

main "$@"
