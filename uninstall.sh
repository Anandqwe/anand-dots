#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║       anand-dots — Uninstall Script           ║
# ║       Hyprland Dotfiles for Arch Linux        ║
# ╚══════════════════════════════════════════════╝

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOG_DIR="$DOTFILES_DIR/install-logs"
LOG="$LOG_DIR/uninstall-$(date +%Y%m%d_%H%M%S).log"

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
echo "anand-dots uninstall log — $(date)" > "$LOG"
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

# ── Input Helper ────────────────────────────────
prompt_yes_no() {
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

# ── Restore or Remove a Config Entry ──────────
remove_config() {
    local target="$1"
    local name
    name="$(basename "$target")"

    if [[ -L "$target" ]]; then
        rm "$target"
        success "Removed symlink: $name"

        # Restore most-recent backup if one exists
        local latest_bak
        latest_bak=$(find "$(dirname "$target")" -maxdepth 1 -name "${name}.bak.*" 2>/dev/null \
            | sort | tail -n1)
        if [[ -n "$latest_bak" ]]; then
            mv "$latest_bak" "$target"
            success "Restored backup: $(basename "$latest_bak") → $name"
        fi
    elif [[ -e "$target" ]]; then
        warn "$name exists but is not a symlink — skipping."
    else
        info "$name not found — nothing to remove."
    fi
}

# ── Remove Config Symlinks ─────────────────────
remove_configs() {
    step "Removing configuration symlinks"
    local configs=(hypr waybar kitty rofi mako wlogout waypaper fastfetch ohmyposh)
    for cfg in "${configs[@]}"; do
        remove_config "$CONFIG_DIR/$cfg"
    done
}

# ── Remove Scripts Symlink ─────────────────────
remove_scripts() {
    step "Removing scripts symlink"
    local dst="$CONFIG_DIR/hypr/scripts"
    if [[ -L "$dst" ]]; then
        rm "$dst"
        success "Removed scripts symlink."
    elif [[ -e "$dst" ]]; then
        warn "scripts/ is not a symlink — skipping."
    else
        info "scripts/ not found — nothing to remove."
    fi
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

# ── Remove Packages ───────────────────────────
remove_packages() {
    step "Removing packages"
    _parse_packages
    local all_pkgs=("${_PACMAN_PKGS[@]}" "${_AUR_PKGS[@]}")

    if [[ ${#all_pkgs[@]} -eq 0 ]]; then
        warn "No packages found in packages.txt."
        return
    fi

    info "Packages to remove:"
    printf '    %s\n' "${all_pkgs[@]}" | tee -a "$LOG"
    echo ""

    if prompt_yes_no "Remove ALL of the above packages?" "n"; then
        sudo pacman -Rns --noconfirm "${all_pkgs[@]}" 2>&1 | tee -a "$LOG" \
            && success "Packages removed." \
            || warn "Some packages may not have been installed — check $LOG"
    else
        info "Skipping package removal."
    fi
}

# ── Remove Directories ────────────────────────
remove_directories() {
    step "Removing created directories"
    local dirs=(
        "$HOME/Pictures/Screenshots"
        "$HOME/Pictures/Wallpapers"
        "$HOME/.cache/anand-dots"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            if prompt_yes_no "Remove $dir and all its contents?" "n"; then
                rm -rf "$dir"
                success "Removed $dir"
            else
                info "Kept $dir"
            fi
        fi
    done
}

# ── Main ──────────────────────────────────────
main() {
    clear
    echo ""
    echo -e "${RED}${BOLD}"
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │       a n a n d - d o t s               │"
    echo "  │          U n i n s t a l l e r           │"
    echo "  └─────────────────────────────────────────┘"
    echo -e "${NC}"
    echo -e "  Log: ${CYAN}$LOG${NC}"
    echo ""

    warn "This will remove all anand-dots symlinks from ~/.config."
    warn "Backed-up configs (*.bak.*) will be restored automatically."
    echo ""

    if ! prompt_yes_no "Continue with uninstall?" "n"; then
        info "Uninstall cancelled."
        exit 0
    fi

    remove_configs
    remove_scripts

    echo ""
    if prompt_yes_no "Remove installed packages listed in packages.txt?" "n"; then
        remove_packages
    else
        info "Skipping package removal."
    fi

    echo ""
    remove_directories

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Uninstall complete!              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    info "Uninstall log saved → $LOG"
    echo ""
}

main "$@"
