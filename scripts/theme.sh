#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║        anand-dots — Theme Switcher            ║
# ║  Usage: theme.sh [theme-name]                 ║
# ║  Themes: catppuccin-mocha dracula             ║
# ║          gruvbox-dark nord tokyo-night        ║
# ╚══════════════════════════════════════════════╝

set -e

# ── Resolve paths ────────────────────────────────
SCRIPT_REAL="$(realpath "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$(dirname "$SCRIPT_REAL")"
DOTFILES_DIR="$(dirname "$SCRIPTS_DIR")"

THEMES_DIR="$DOTFILES_DIR/themes"
CONFIGS_DIR="$DOTFILES_DIR/configs"

HYPR_CONF="$HOME/.config/hypr"
WAYBAR_CONF="$HOME/.config/waybar"
KITTY_CONF="$HOME/.config/kitty"
WOFI_CONF="$HOME/.config/wofi"
MAKO_CONF="$HOME/.config/mako"

# ── Colors for output ────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}[theme]${NC} $1"; }
success() { echo -e "${GREEN}[theme]${NC} $1"; }
warn()    { echo -e "${YELLOW}[theme]${NC} $1"; }
err()     { echo -e "${RED}[theme]${NC} $1" >&2; exit 1; }

# ── List available themes ───────────────────────
list_themes() {
    find "$THEMES_DIR" -name "*.conf" | sed 's/.*\///' | sed 's/\.conf//' | sort
}

# ── Pick theme with wofi ────────────────────────
pick_theme() {
    list_themes | wofi --dmenu \
        --prompt "Select theme" \
        --insensitive \
        --width 300 --height 250 \
        --no-actions
}

# ── Parse theme file: extract varname→hex ───────
# Input: path to theme .conf file
# Output: associative array populated by caller
load_colors() {
    local theme_file="$1"
    while IFS= read -r line; do
        # Match:  $varname = rgb(xxxxxx)
        if [[ "$line" =~ ^\$([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*rgb\(([0-9a-fA-F]{6})\) ]]; then
            local varname="${BASH_REMATCH[1]}"
            local hexval="${BASH_REMATCH[2]}"
            COLORS["$varname"]="$hexval"
        fi
    done < "$theme_file"
}

# ── Apply template: replace {{var}} placeholders ─
# Usage: apply_template <template_file> <output_file> <theme_name>
apply_template() {
    local tpl="$1"
    local out="$2"
    local theme_name="$3"

    [[ -f "$tpl" ]] || { warn "Template not found: $tpl"; return 1; }

    local content
    content="$(cat "$tpl")"

    # Replace {{theme_name}}
    content="${content//\{\{theme_name\}\}/$theme_name}"

    # Replace {{varname}} → #hexval  and  {{varname_hex}} → hexval
    for varname in "${!COLORS[@]}"; do
        local hexval="${COLORS[$varname]}"
        content="${content//\{\{${varname}\}\}/#${hexval}}"
        content="${content//\{\{${varname}_hex\}\}/${hexval}}"
    done

    printf '%s\n' "$content" > "$out"
}

# ── Update hyprland theme.conf symlink ──────────
apply_hypr_theme() {
    local theme_file="$1"
    local target="$HYPR_CONF/theme.conf"

    # Remove old symlink or file
    [[ -L "$target" ]] && rm "$target"
    [[ -f "$target" ]] && rm "$target"

    ln -sf "$theme_file" "$target"
}

# ── Save current theme name ─────────────────────
save_theme() {
    local theme_name="$1"
    local cache_file="$HOME/.cache/anand-dots/current-theme"
    mkdir -p "$(dirname "$cache_file")"
    echo "$theme_name" > "$cache_file"
}

# ── Reload services ─────────────────────────────
reload_services() {
    info "Reloading services..."

    # Reload Hyprland (re-sources theme.conf)
    if command -v hyprctl &>/dev/null; then
        hyprctl reload &>/dev/null && info "  hyprland reloaded" || warn "  hyprland reload failed"
    fi

    # Restart Waybar
    if pgrep -x waybar &>/dev/null; then
        pkill -x waybar || true
        sleep 0.3
        waybar &>/dev/null &
        disown
        info "  waybar restarted"
    fi

    # Restart Mako
    if pgrep -x mako &>/dev/null; then
        pkill -x mako || true
        sleep 0.2
        mako &>/dev/null &
        disown
        info "  mako restarted"
    elif command -v mako &>/dev/null; then
        mako &>/dev/null &
        disown
    fi

    # Kitty reloads on SIGUSR1 if running
    if pgrep -x kitty &>/dev/null; then
        pkill -USR1 -x kitty || true
        info "  kitty reloaded"
    fi
}

# ── Main ─────────────────────────────────────────
main() {
    local theme_name="$1"

    # If no argument, try wofi picker; fall back to listing themes
    if [[ -z "$theme_name" ]]; then
        if command -v wofi &>/dev/null; then
            theme_name="$(pick_theme)" || err "No theme selected."
        else
            echo "Available themes:"
            list_themes | sed 's/^/  /'
            echo ""
            echo "Usage: $(basename "$0") <theme-name>"
            exit 0
        fi
    fi

    [[ -z "$theme_name" ]] && err "No theme selected."

    local theme_file="$THEMES_DIR/${theme_name}.conf"
    [[ -f "$theme_file" ]] || err "Theme not found: $theme_name\nAvailable: $(list_themes | tr '\n' ' ')"

    info "Applying theme: $theme_name"

    # Load colors from theme file
    declare -A COLORS
    load_colors "$theme_file"

    # Apply each template
    apply_template "$CONFIGS_DIR/waybar/style.css.tpl"      "$WAYBAR_CONF/style.css"         "$theme_name"
    success "  waybar style updated"

    apply_template "$CONFIGS_DIR/wofi/style.css.tpl"        "$WOFI_CONF/style.css"           "$theme_name"
    success "  wofi style updated"

    apply_template "$CONFIGS_DIR/mako/config.tpl"           "$MAKO_CONF/config"              "$theme_name"
    success "  mako config updated"

    apply_template "$CONFIGS_DIR/kitty/kitty.conf.tpl"      "$KITTY_CONF/kitty.conf"         "$theme_name"
    success "  kitty config updated"

    apply_template "$CONFIGS_DIR/hypr/hyprlock.conf.tpl"    "$HYPR_CONF/hyprlock.conf"       "$theme_name"
    success "  hyprlock config updated"

    # Update hyprland theme.conf symlink
    apply_hypr_theme "$theme_file"
    success "  hyprland theme.conf → $theme_name"

    # Save for restore script / status
    save_theme "$theme_name"

    # Reload everything
    reload_services

    echo ""
    success "Theme '$theme_name' applied successfully."
}

main "$@"
