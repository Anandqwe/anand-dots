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
DRY_RUN=0
PROFILE=""

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
# Usage: install.sh [-p] [-d] [-c] [-s] [-t] [-a] [-n] [-P profile]
#   -p  install packages       -d  create directories
#   -c  link configs            -s  link scripts
#   -t  apply theme             -a  all steps (default if no flags)
#   -n  dry-run (no changes)    -P  preset profile (full|core|rice)
_do_packages=0 _do_dirs=0 _do_configs=0 _do_scripts=0 _do_theme=0

while getopts "pdcstanhP:" opt; do
    case "$opt" in
        p) _do_packages=1 ;;
        d) _do_dirs=1 ;;
        c) _do_configs=1 ;;
        s) _do_scripts=1 ;;
        t) _do_theme=1 ;;
        a) _do_packages=1; _do_dirs=1; _do_configs=1; _do_scripts=1; _do_theme=1 ;;
        n) DRY_RUN=1 ;;
        P) PROFILE="${OPTARG,,}" ;;
        h)
            echo "Usage: $0 [-p] [-d] [-c] [-s] [-t] [-a] [-n] [-P profile]"
            echo "  -p  Install packages (pacman + AUR)"
            echo "  -d  Create directories and copy wallpapers"
            echo "  -c  Link configuration files"
            echo "  -s  Link scripts and make them executable"
            echo "  -t  Apply Material You colors from wallpaper"
            echo "  -a  All steps (non-interactive)"
            echo "  -n  Dry-run mode (show actions, perform no writes)"
            echo "  -P  Preset profile: full | core | rice"
            echo "  (no flags)  Interactive mode — prompts for each step"
            exit 0 ;;
        *) echo "Unknown option. Run '$0 -h' for help." ; exit 1 ;;
    esac
done

apply_profile() {
    case "$PROFILE" in
        "") return 0 ;;
        full)
            _do_packages=1; _do_dirs=1; _do_configs=1; _do_scripts=1; _do_theme=1 ;;
        core)
            _do_packages=1; _do_dirs=1; _do_configs=1; _do_scripts=1 ;;
        rice)
            _do_dirs=1; _do_configs=1; _do_scripts=1; _do_theme=1 ;;
        *)
            error "Invalid profile '$PROFILE'. Use one of: full, core, rice." ;;
    esac
}

apply_profile

INTERACTIVE=0
if [[ $(( _do_packages + _do_dirs + _do_configs + _do_scripts + _do_theme )) -eq 0 ]]; then
    INTERACTIVE=1
fi

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Dry-run mode enabled: no files or packages will be modified."
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

check_required_files() {
    local required=(
        "$DOTFILES_DIR/packages.txt"
        "$DOTFILES_DIR/configs/hypr"
        "$DOTFILES_DIR/scripts"
    )

    local missing=0 item
    for item in "${required[@]}"; do
        if [[ ! -e "$item" ]]; then
            warn "Missing required path: $item"
            missing=1
        fi
    done

    [[ $missing -eq 0 ]] || error "Required files are missing. Re-clone the repo and try again."
}

wait_for_pacman_lock() {
    local lock_file="/var/lib/pacman/db.lck"
    local timeout=60
    local waited=0

    while [[ -f "$lock_file" ]]; do
        if (( waited == 0 )); then
            warn "Pacman lock detected. Waiting for other package operations to finish..."
        fi
        sleep 1
        ((waited++))
        if (( waited >= timeout )); then
            error "Pacman lock remained for ${timeout}s. Please finish other package operations and retry."
        fi
    done

    (( waited > 0 )) && success "Pacman lock cleared."
}

preflight_checks() {
    step "Running preflight checks"

    check_required_files

    local cmds=(bash git pacman sudo find ln)
    local missing_cmds=()
    local c
    for c in "${cmds[@]}"; do
        command -v "$c" &>/dev/null || missing_cmds+=("$c")
    done

    if [[ ${#missing_cmds[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing_cmds[*]}"
    fi

    wait_for_pacman_lock

    if [[ $DRY_RUN -eq 0 ]]; then
        info "Validating sudo permissions..."
        sudo -v || error "Unable to acquire sudo credentials."
    else
        info "Dry-run: skipping sudo credential validation."
    fi

    if ping -c 1 archlinux.org &>/dev/null; then
        success "Network connectivity looks good."
    else
        warn "Could not verify internet connectivity. Package installs may fail."
    fi
}

apply_colors() {
    step "Applying Material You colors"
    local matugen_script="$DOTFILES_DIR/scripts/matugen-apply.sh"

    if ! command -v matugen &>/dev/null; then
        warn "matugen not installed — skipping color generation."
        warn "Colors will be applied on first wallpaper change."
        return
    fi

    # Find a wallpaper to generate colors from
    local wallpaper
    wallpaper=$(find "$HOME/Pictures/Wallpapers" -type f \
        \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) \
        2>/dev/null | head -1)

    if [[ -z "$wallpaper" ]]; then
        warn "No wallpapers found — colors will be applied on first wallpaper change."
        return
    fi

    if [[ -f "$matugen_script" ]]; then
        bash "$matugen_script" "$wallpaper" 2>&1 | tee -a "$LOG" \
            && success "Material You colors applied from: $(basename "$wallpaper")" \
            || warn "Color generation failed — will retry on wallpaper change."
    fi
}

# ── Dependency Checks ────────────────────────────
check_deps() {
    step "Checking dependencies"

    if [[ $DRY_RUN -eq 1 ]]; then
        info "Dry-run: would verify base-devel and AUR helper (yay/paru)."
        if command -v yay &>/dev/null; then
            AUR_HELPER="yay"
            success "Dry-run detected AUR helper: yay"
        elif command -v paru &>/dev/null; then
            AUR_HELPER="paru"
            success "Dry-run detected AUR helper: paru"
        else
            warn "Dry-run: no AUR helper found. Would prompt to install yay/paru."
        fi
        return
    fi

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
    if [[ $DRY_RUN -eq 1 ]]; then
        info "Dry-run: would clone/build AUR helper '$helper'."
        return
    fi
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

    if [[ $DRY_RUN -eq 1 ]]; then
        info "Dry-run: package installation plan"
        [[ ${#_PACMAN_PKGS[@]} -gt 0 ]] && info "Pacman (${#_PACMAN_PKGS[@]}): ${_PACMAN_PKGS[*]}"
        [[ ${#_AUR_PKGS[@]} -gt 0 ]] && info "AUR (${#_AUR_PKGS[@]}): ${_AUR_PKGS[*]}"
        return
    fi

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
        if [[ $DRY_RUN -eq 1 ]]; then
            info "Dry-run: would link $dst -> $src"
            continue
        fi
        _backup "$dst"
        ln -sf "$src" "$dst"
        success "Linked  $cfg"
    done
}

# ── Link Scripts ──────────────────────────────
link_scripts() {
    step "Setting up scripts"
    local dst="$CONFIG_DIR/hypr/scripts"

    if [[ $DRY_RUN -eq 1 ]]; then
        info "Dry-run: would link $dst -> $DOTFILES_DIR/scripts"
        info "Dry-run: would chmod +x scripts/*.sh and settings/main.py"
        return
    fi

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
        if [[ $DRY_RUN -eq 1 ]]; then
            info "Dry-run: would ensure $d"
            continue
        fi
        mkdir -p "$d" && success "Ensured $d"
    done

    if [[ $DRY_RUN -eq 1 ]]; then
        info "Dry-run: would copy bundled wallpapers into ~/Pictures/Wallpapers"
        return
    fi

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

    if [[ $DRY_RUN -eq 1 ]]; then
        info "Dry-run: would enable services: ${services[*]}"
        return
    fi

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
    if [[ $DRY_RUN -eq 1 ]]; then
        info "Dry-run: skipping reboot prompt."
        return
    fi

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

    if [[ -n "$PROFILE" ]]; then
        info "Using profile: $PROFILE"
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
        warn "Dry-run mode is active."
    fi

    # ── Pre-flight ──────────────────────────
    preflight_checks
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

    # ── Colors ───────────────────────────────
    if ask_step "$_do_theme" "[5/5] Apply Material You colors from wallpaper?"; then
        apply_colors
    else
        info "Skipping color setup."
        info "Colors will be applied automatically on wallpaper change."
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
    if [[ $DRY_RUN -eq 0 ]]; then
        verify_packages
    else
        info "Dry-run: skipping package verification."
    fi

    # ── Done ────────────────────────────────
    print_summary
    prompt_reboot
}

main "$@"
