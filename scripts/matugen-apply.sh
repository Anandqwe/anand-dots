#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║     anand-dots — Matugen Dynamic Colors       ║
# ║  Generate Material You colors from wallpaper  ║
# ║  Usage: matugen-apply.sh <wallpaper-path>     ║
# ╚══════════════════════════════════════════════╝

set -e

SCRIPT_REAL="$(realpath "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$(dirname "$SCRIPT_REAL")"
DOTFILES_DIR="$(dirname "$SCRIPTS_DIR")"

CONFIGS_DIR="$DOTFILES_DIR/configs"
CACHE_DIR="$HOME/.cache/anand-dots"

HYPR_CONF="$HOME/.config/hypr"
WAYBAR_CONF="$HOME/.config/waybar"
KITTY_CONF="$HOME/.config/kitty"
ROFI_CONF="$HOME/.config/rofi"
MAKO_CONF="$HOME/.config/mako"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}[matugen]${NC} $1"; }
success() { echo -e "${GREEN}[matugen]${NC} $1"; }
warn()    { echo -e "${YELLOW}[matugen]${NC} $1"; }
err()     { echo -e "${RED}[matugen]${NC} $1" >&2; exit 1; }

# ── Check dependencies ──────────────────────────
command -v matugen &>/dev/null || err "matugen not installed. Install: paru -S matugen-bin"
command -v jq &>/dev/null || err "jq not installed. Install: sudo pacman -S jq"

WALLPAPER="$1"
[[ -n "$WALLPAPER" && -f "$WALLPAPER" ]] || err "Usage: matugen-apply.sh <wallpaper-path>"

# ── Generate colors ─────────────────────────────
info "Generating colors from: $(basename "$WALLPAPER")"

# --source-color-index 0 picks the first extracted color automatically,
# bypassing the interactive TUI picker (required for non-TTY/background use).
JSON=$(matugen -j hex image --source-color-index 0 "$WALLPAPER" 2>/dev/null) || err "matugen failed to generate colors from: $WALLPAPER"

# ── Extract Material You colors (dark scheme) ───
# matugen v4 JSON structure: .colors.<name>.dark.color
# Helper: extract color from JSON, strip leading #
c() { echo "$JSON" | jq -r ".colors.${1}.dark.color" | sed 's/^#//'; }

# Material You color roles
primary=$(c "primary")
on_primary=$(c "on_primary")
primary_container=$(c "primary_container")
on_primary_container=$(c "on_primary_container")
secondary=$(c "secondary")
secondary_container=$(c "secondary_container")
on_secondary_container=$(c "on_secondary_container")
tertiary=$(c "tertiary")
tertiary_container=$(c "tertiary_container")
on_tertiary_container=$(c "on_tertiary_container")
error_color=$(c "error")
error_container=$(c "error_container")
surface=$(c "surface")
surface_dim=$(c "surface_dim")
surface_bright=$(c "surface_bright")
surface_container_lowest=$(c "surface_container_lowest")
surface_container_low=$(c "surface_container_low")
surface_container=$(c "surface_container")
surface_container_high=$(c "surface_container_high")
surface_container_highest=$(c "surface_container_highest")
on_surface=$(c "on_surface")
on_surface_variant=$(c "on_surface_variant")
outline=$(c "outline")
outline_variant=$(c "outline_variant")
inverse_surface=$(c "inverse_surface")

# ── Map to catppuccin-style template variables ───
# This mapping lets us reuse the existing templates
declare -A COLORS
COLORS[rosewater]="$tertiary"
COLORS[flamingo]="$tertiary_container"
COLORS[pink]="$tertiary"
COLORS[mauve]="$secondary"
COLORS[red]="$error_color"
COLORS[maroon]="$error_container"
COLORS[peach]="$on_tertiary_container"
COLORS[yellow]="$on_primary_container"
COLORS[green]="$primary_container"
COLORS[teal]="$secondary_container"
COLORS[sky]="$on_secondary_container"
COLORS[sapphire]="$primary_container"
COLORS[blue]="$primary"
COLORS[lavender]="$secondary"
COLORS[text]="$on_surface"
COLORS[subtext1]="$on_surface_variant"
COLORS[subtext0]="$outline"
COLORS[overlay2]="$outline"
COLORS[overlay1]="$outline_variant"
COLORS[overlay0]="$surface_container_highest"
COLORS[surface2]="$surface_container_high"
COLORS[surface1]="$surface_container"
COLORS[surface0]="$surface_container_low"
COLORS[base]="$surface"
COLORS[mantle]="$surface_dim"
COLORS[crust]="$surface_container_lowest"

# ── Apply templates (same logic as theme.sh) ────
apply_template() {
    local tpl="$1"
    local out="$2"
    local theme_name="$3"

    [[ -f "$tpl" ]] || { warn "Template not found: $tpl"; return 1; }

    local content
    content="$(cat "$tpl")"

    content="${content//\{\{theme_name\}\}/$theme_name}"

    for varname in "${!COLORS[@]}"; do
        local hexval="${COLORS[$varname]}"
        content="${content//\{\{${varname}\}\}/#${hexval}}"
        content="${content//\{\{${varname}_hex\}\}/${hexval}}"
    done

    printf '%s\n' "$content" > "$out"
}

THEME_NAME="matugen-dynamic"

apply_template "$CONFIGS_DIR/waybar/style.css.tpl"      "$WAYBAR_CONF/style.css"         "$THEME_NAME"
success "  waybar style updated"

apply_template "$CONFIGS_DIR/rofi/colors.rasi.tpl"      "$ROFI_CONF/colors.rasi"         "$THEME_NAME"
success "  rofi colors updated"

apply_template "$CONFIGS_DIR/mako/config.tpl"           "$MAKO_CONF/config"              "$THEME_NAME"
success "  mako config updated"

apply_template "$CONFIGS_DIR/kitty/kitty.conf.tpl"      "$KITTY_CONF/kitty.conf"         "$THEME_NAME"
success "  kitty config updated"

apply_template "$CONFIGS_DIR/hypr/hyprlock.conf.tpl"    "$HYPR_CONF/hyprlock.conf"       "$THEME_NAME"
success "  hyprlock config updated"

# ── Write a dynamic theme.conf for Hyprland ─────
DYNAMIC_THEME="$HYPR_CONF/theme.conf"
# Remove old symlink if it exists (from theme.sh)
[[ -L "$DYNAMIC_THEME" ]] && rm "$DYNAMIC_THEME"
{
    echo "# ── Dynamic Theme (matugen) ──────────────────────"
    echo "# Auto-generated from wallpaper: $(basename "$WALLPAPER")"
    echo ""
    for varname in "${!COLORS[@]}"; do
        printf '$%s = rgb(%s)\n' "$varname" "${COLORS[$varname]}"
    done
} > "$DYNAMIC_THEME"
success "  hyprland theme.conf updated"

# ── Save state ──────────────────────────────────
mkdir -p "$CACHE_DIR"
echo "$THEME_NAME" > "$CACHE_DIR/current-theme"

# ── Reload services ─────────────────────────────
info "Reloading services..."

if command -v hyprctl &>/dev/null; then
    hyprctl reload &>/dev/null && info "  hyprland reloaded" || warn "  hyprland reload failed"
fi

if pgrep -x waybar &>/dev/null; then
    pkill -x waybar || true
    sleep 0.3
    waybar &>/dev/null &
    disown
    info "  waybar restarted"
fi

if pgrep -x mako &>/dev/null; then
    pkill -x mako || true
    sleep 0.2
    mako &>/dev/null &
    disown
    info "  mako restarted"
fi

if pgrep -x kitty &>/dev/null; then
    pkill -USR1 -x kitty || true
    info "  kitty reloaded"
fi

echo ""
success "Dynamic colors applied from: $(basename "$WALLPAPER")"
