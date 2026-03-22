#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║     anand-dots — Material You Dynamic Colors  ║
# ║  Production-grade color engine for Hyprland   ║
# ║  Usage: matugen-apply.sh <wallpaper-path>     ║
# ╚══════════════════════════════════════════════╝
#
# Pipeline:
#   Wallpaper → matugen → Material roles → Derived colors
#            → Accent palette → Terminal harmony → theme.conf
#            → Waybar / Kitty / Rofi / GTK / Mako / Hyprlock

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

# Set to 0 to preserve an existing Waybar style.css during this run.
# Useful when users want dynamic colors for other components but keep a custom Waybar theme.
UPDATE_WAYBAR_STYLE="${ANAND_DOTS_UPDATE_WAYBAR_STYLE:-1}"

CLR_GREEN='\033[0;32m'
CLR_BLUE='\033[0;34m'
CLR_YELLOW='\033[1;33m'
CLR_RED='\033[0;31m'
CLR_NC='\033[0m'

info()    { echo -e "${CLR_BLUE}[matugen]${CLR_NC} $1"; }
success() { echo -e "${CLR_GREEN}[matugen]${CLR_NC} $1"; }
warn()    { echo -e "${CLR_YELLOW}[matugen]${CLR_NC} $1"; }
err()     { echo -e "${CLR_RED}[matugen]${CLR_NC} $1" >&2; exit 1; }

# ── Check dependencies ──────────────────────────
command -v matugen &>/dev/null || err "matugen not installed. Install: paru -S matugen-bin"
command -v jq &>/dev/null || err "jq not installed. Install: sudo pacman -S jq"

WALLPAPER="$1"
[[ -n "$WALLPAPER" && -f "$WALLPAPER" ]] || err "Usage: matugen-apply.sh <wallpaper-path>"

# ════════════════════════════════════════════════
#  Color utilities
# ════════════════════════════════════════════════

# mix_hex <hex1> <hex2> <factor>
#   Blends two hex colors. factor = weight of hex1 (0.0 → all hex2, 1.0 → all hex1).
#   Returns a 6-char hex string (no #).
mix_hex() {
    local c1="${1//#/}" c2="${2//#/}" f="$3"
    local r1 g1 b1 r2 g2 b2
    r1=$((16#${c1:0:2})); g1=$((16#${c1:2:2})); b1=$((16#${c1:4:2}))
    r2=$((16#${c2:0:2})); g2=$((16#${c2:2:2})); b2=$((16#${c2:4:2}))
    awk -v r1="$r1" -v g1="$g1" -v b1="$b1" \
        -v r2="$r2" -v g2="$g2" -v b2="$b2" \
        -v f="$f" \
        'BEGIN{ printf "%02x%02x%02x",
            int(r1*f + r2*(1-f) + 0.5),
            int(g1*f + g2*(1-f) + 0.5),
            int(b1*f + b2*(1-f) + 0.5) }'
}

# harmonize_hex <source_hex> <target_hex> <factor>
#   Shifts the hue of source toward target by (1-factor) of the angular difference.
#   Preserves source saturation and lightness (HSL model).
#   Ex: factor=0.8 → 20% hue shift toward target; factor=1.0 → source unchanged.
#
#   This mirrors the Material Design 3 color harmonization algorithm used in
#   Android's dynamic color system to keep semantic colors (red/green/yellow)
#   recognizable while visually tying them to the dominant wallpaper accent.
harmonize_hex() {
    local c1="${1//#/}" c2="${2//#/}" f="$3"
    awk \
        -v c1="$(printf '%s' "$c1" | tr '[:upper:]' '[:lower:]')" \
        -v c2="$(printf '%s' "$c2" | tr '[:upper:]' '[:lower:]')" \
        -v f="$f" '
    # Parse one byte from a lowercase hex string at 1-based byte position p.
    function hb(s, p,   h, hi, lo) {
        h  = substr(s, p, 2)
        hi = index("0123456789abcdef", substr(h,1,1)) - 1
        lo = index("0123456789abcdef", substr(h,2,1)) - 1
        return hi * 16 + lo
    }
    # RGB → hue (degrees 0–360).
    function rgb2hue(r, g, b,   rn, gn, bn, mx, mn, d, h) {
        rn=r/255; gn=g/255; bn=b/255
        mx = (rn>gn && rn>bn) ? rn : (gn>bn ? gn : bn)
        mn = (rn<gn && rn<bn) ? rn : (gn<bn ? gn : bn)
        d  = mx - mn
        if (d == 0) return 0
        if      (mx == rn) { h = (gn-bn)/d; h = h - int(h/6)*6 }
        else if (mx == gn)   h = (bn-rn)/d + 2
        else                 h = (rn-gn)/d + 4
        h = h * 60
        if (h < 0) h += 360
        return h
    }
    # RGB → saturation + lightness (HSL), returned as "s\031l".
    function rgb2sl(r, g, b,   rn, gn, bn, mx, mn, d, s, l) {
        rn=r/255; gn=g/255; bn=b/255
        mx = (rn>gn && rn>bn) ? rn : (gn>bn ? gn : bn)
        mn = (rn<gn && rn<bn) ? rn : (gn<bn ? gn : bn)
        d  = mx - mn
        l  = (mx + mn) / 2
        s  = (d == 0) ? 0 : d / (1 - (2*l-1 >= 0 ? 2*l-1 : -(2*l-1)))
        return s SUBSEP l
    }
    # HSL → 6-char hex string.
    function hsl2hex(h, s, l,   c, hp, t, x, m, r, g, b, ri, gi, bi) {
        c  = (1 - (2*l-1 >= 0 ? 2*l-1 : -(2*l-1))) * s
        hp = h / 60
        t  = hp - int(hp/2)*2
        x  = c * (1 - (t-1 >= 0 ? t-1 : -(t-1)))
        m  = l - c/2
        if      (hp < 1) { r=c; g=x; b=0 }
        else if (hp < 2) { r=x; g=c; b=0 }
        else if (hp < 3) { r=0; g=c; b=x }
        else if (hp < 4) { r=0; g=x; b=c }
        else if (hp < 5) { r=x; g=0; b=c }
        else             { r=c; g=0; b=x }
        ri=int((r+m)*255+0.5); if(ri<0)ri=0; if(ri>255)ri=255
        gi=int((g+m)*255+0.5); if(gi<0)gi=0; if(gi>255)gi=255
        bi=int((b+m)*255+0.5); if(bi<0)bi=0; if(bi>255)bi=255
        return sprintf("%02x%02x%02x", ri, gi, bi)
    }
    BEGIN {
        r1=hb(c1,1); g1=hb(c1,3); b1=hb(c1,5)
        r2=hb(c2,1); g2=hb(c2,3); b2=hb(c2,5)
        h1 = rgb2hue(r1, g1, b1)
        h2 = rgb2hue(r2, g2, b2)
        split(rgb2sl(r1, g1, b1), sl1, SUBSEP)
        s1=sl1[1]+0; l1=sl1[2]+0
        # Angular diff normalized to [-180, 180] for shortest-path hue rotation.
        d = h2 - h1
        while (d >  180) d -= 360
        while (d < -180) d += 360
        h_new = h1 + (1-f) * d
        if (h_new <   0) h_new += 360
        if (h_new >= 360) h_new -= 360
        print hsl2hex(h_new, s1, l1)
    }'
}

# hsl_to_hex <hue_deg> <saturation_0-1> <lightness_0-1>
#   Generates a hex color from HSL values.
#   Used to produce ANSI-base colors before harmonization.
hsl_to_hex() {
    local h="$1" s="$2" l="$3"
    awk -v h="$h" -v s="$s" -v l="$l" '
    BEGIN {
        c  = (1 - (2*l-1 >= 0 ? 2*l-1 : -(2*l-1))) * s
        hp = h / 60
        t  = hp - int(hp/2)*2
        x  = c * (1 - (t-1 >= 0 ? t-1 : -(t-1)))
        m  = l - c/2
        if      (hp < 1) { r=c; g=x; b=0 }
        else if (hp < 2) { r=x; g=c; b=0 }
        else if (hp < 3) { r=0; g=c; b=x }
        else if (hp < 4) { r=0; g=x; b=c }
        else if (hp < 5) { r=x; g=0; b=c }
        else             { r=c; g=0; b=x }
        ri=int((r+m)*255+0.5); if(ri<0)ri=0; if(ri>255)ri=255
        gi=int((g+m)*255+0.5); if(gi<0)gi=0; if(gi>255)gi=255
        bi=int((b+m)*255+0.5); if(bi<0)bi=0; if(bi>255)bi=255
        printf "%02x%02x%02x\n", ri, gi, bi
    }'
}

# boost_color <hex>
#   Chroma boosting + tone correction for accent colors.
#
#   Smart boost  — only acts when the color actually needs it:
#     saturation  < 0.60  → boost by ×1.20, capped at 0.85
#     lightness   < 0.60  → lift to 0.65,   capped at 0.85
#
#   This mirrors Android SystemUI's chroma mapping which ensures accent
#   colors remain vivid and readable even from low-chroma wallpapers,
#   while leaving already-vibrant colors completely untouched.
boost_color() {
    local c="${1//#/}"
    awk -v c="$(printf '%s' "$c" | tr '[:upper:]' '[:lower:]')" '
    function hb(s, p,   hi, lo) {
        hi = index("0123456789abcdef", substr(s,p,1)) - 1
        lo = index("0123456789abcdef", substr(s,p+1,1)) - 1
        return hi * 16 + lo
    }
    function rgb2hsl(r, g, b,   rn, gn, bn, mx, mn, d, h, s, l) {
        rn=r/255; gn=g/255; bn=b/255
        mx=(rn>gn&&rn>bn)?rn:(gn>bn?gn:bn)
        mn=(rn<gn&&rn<bn)?rn:(gn<bn?gn:bn)
        d=mx-mn; l=(mx+mn)/2
        if (d==0) { h=0; s=0 }
        else {
            s = d / (1 - (2*l-1>=0 ? 2*l-1 : -(2*l-1)))
            if      (mx==rn) { h=(gn-bn)/d; h=h-int(h/6)*6 }
            else if (mx==gn)   h=(bn-rn)/d+2
            else               h=(rn-gn)/d+4
            h=h*60; if(h<0)h+=360
        }
        return h SUBSEP s SUBSEP l
    }
    function hsl2hex(h, s, l,   c2, hp, t, x, m, r, g, b, ri, gi, bi) {
        c2=(1-(2*l-1>=0?2*l-1:-(2*l-1)))*s
        hp=h/60; t=hp-int(hp/2)*2
        x=c2*(1-(t-1>=0?t-1:-(t-1)))
        m=l-c2/2
        if      (hp<1){r=c2;g=x;b=0}  else if(hp<2){r=x;g=c2;b=0}
        else if (hp<3){r=0;g=c2;b=x}  else if(hp<4){r=0;g=x;b=c2}
        else if (hp<5){r=x;g=0;b=c2}  else{r=c2;g=0;b=x}
        ri=int((r+m)*255+0.5); if(ri<0)ri=0; if(ri>255)ri=255
        gi=int((g+m)*255+0.5); if(gi<0)gi=0; if(gi>255)gi=255
        bi=int((b+m)*255+0.5); if(bi<0)bi=0; if(bi>255)bi=255
        return sprintf("%02x%02x%02x",ri,gi,bi)
    }
    BEGIN {
        r=hb(c,1); g=hb(c,3); b=hb(c,5)
        split(rgb2hsl(r,g,b), hsl, SUBSEP)
        h=hsl[1]+0; s=hsl[2]+0; l=hsl[3]+0
        # Smart chroma boost — only when under-saturated
        if (s < 0.60) { s = s * 1.20; if (s > 0.85) s = 0.85 }
        # Tone correction — lift dark accents to dark-mode readable range
        if (l < 0.60) { l = 0.65;     if (l > 0.85) l = 0.85 }
        print hsl2hex(h, s, l)
    }'
}

# ════════════════════════════════════════════════
#  Dominant color extraction  (ImageMagick)
# ════════════════════════════════════════════════

# hex_saturation <hex>
#   Returns the HSL saturation (0.0–1.0) of a 6-char hex color.
#   Used for both neutral detection and filtering in extraction.
hex_saturation() {
    local c="${1//#/}"
    awk -v c="$(printf '%s' "$c" | tr '[:upper:]' '[:lower:]')" '
    function hb(s, p) {
        return (index("0123456789abcdef",substr(s,p,1))-1)*16 \
              + index("0123456789abcdef",substr(s,p+1,1))-1
    }
    BEGIN {
        r=hb(c,1)/255; g=hb(c,3)/255; b=hb(c,5)/255
        mx=(r>g&&r>b)?r:(g>b?g:b)
        mn=(r<g&&r<b)?r:(g<b?g:b)
        d=mx-mn; l=(mx+mn)/2
        bl=2*l-1; if(bl<0) bl=-bl
        print (d==0) ? 0 : d/(1-bl)
    }'
}

# extract_dominant_colors <wallpaper> <count>
#   Extracts up to <count> visually dominant, chromatically significant hex
#   colors from the wallpaper using ImageMagick color quantization.
#
#   Process:
#     1. Downscale to 150x150 (speed + noise reduction)
#     2. Quantize to 32 colors (captures variety, avoids dithering noise)
#     3. Filter out: near-black (L<0.15), near-white (L>0.90), achromatic (S<0.20)
#     4. Score remaining colors by: pixel_count × saturation × sqrt(lightness)
#        — this vivid-bias ranking ensures that a bright lantern glow or flame
#          beats the vast near-black background that dominates dark wallpapers
#     5. Return top <count> by vivid-bias score, one hex per line (no #)
#
#   Why vivid-bias? Pure pixel-count ranking picks near-black colors on dark
#   atmospheric wallpapers (night scenes, fire, autumn) because those dark
#   pixels are far more numerous than the vivid accent colors. The vivid-bias
#   score rewards saturation and lightness so the seed color is always one that
#   looks like the wallpaper — not just one that occupies the most pixels.
extract_dominant_colors() {
    local wall="$1" n="${2:-3}"
    command -v convert &>/dev/null || { echo ""; return; }
    # Pass "count hex" pairs to awk so we can score by both count and vividness.
    convert "$wall" -resize 150x150\! +dither -colors 32 \
        -format "%c" histogram:info:- 2>/dev/null \
    | awk -v n="$n" '
        function hb(s, p) {
            return (index("0123456789abcdef",substr(tolower(s),p,1))-1)*16 \
                  + index("0123456789abcdef",substr(tolower(s),p+1,1))-1
        }
        {
            # Extract pixel count (leading integer before the first colon)
            cnt = $0; sub(/:.*/, "", cnt); cnt = cnt + 0
            # Extract hex colour (6 chars after the last #)
            hex = $0; if (!match(hex, /#[0-9A-Fa-f]{6}/)) next
            c = tolower(substr(hex, RSTART+1, 6))
            if (length(c) != 6) next
            r=hb(c,1)/255; g=hb(c,3)/255; b=hb(c,5)/255
            mx=(r>g&&r>b)?r:(g>b?g:b)
            mn=(r<g&&r<b)?r:(g<b?g:b)
            d=mx-mn; lv=(mx+mn)/2
            bl=2*lv-1; if(bl<0) bl=-bl
            sat=(d==0)?0:d/(1-bl)
            # Filter: skip near-black, near-white, and achromatic colors
            if (sat < 0.20 || lv < 0.15 || lv > 0.90) next
            # Vivid-bias score: reward saturation and lightness over raw count.
            # sqrt(lv) dampens the lightness factor so mid-tone accents beat
            # very pale near-white colors on bright wallpapers.
            score = cnt * sat * sqrt(lv)
            scores[NR] = score; hexes[NR] = c; total++
        }
        END {
            # Insertion-sort by descending score (at most 32 entries — negligible cost)
            for (i = 1; i <= total; i++) {
                for (j = i+1; j <= total; j++) {
                    if (scores[j] > scores[i]) {
                        ts=scores[i]; scores[i]=scores[j]; scores[j]=ts
                        th=hexes[i];  hexes[i]=hexes[j];   hexes[j]=th
                    }
                }
            }
            out = 0
            for (i = 1; i <= total; i++) {
                print hexes[i]
                if (++out >= n) break
            }
        }
    '
}

# ════════════════════════════════════════════════
#  Wallpaper analysis: dominant colors + scheme
# ════════════════════════════════════════════════

CONTRAST="0.2"
SCHEME_TYPE="scheme-vibrant"

# Load user preference saved by the Settings GUI.
SCHEME_CACHE="$CACHE_DIR/scheme-type"
[[ -f "$SCHEME_CACHE" ]] && SCHEME_TYPE="$(cat "$SCHEME_CACHE")"
# Keep original so we write the USER'S preference back to cache, not the
# auto-detected override (which would corrupt the preference on next run).
USER_SCHEME_TYPE="$SCHEME_TYPE"

# Dominant color state — populated below when ImageMagick is available.
dom1="" dom2="" dom3=""

if command -v convert &>/dev/null; then
    # ── Extract dominant chromatic colors ──
    mapfile -t _DOMINANT < <(extract_dominant_colors "$WALLPAPER" 3)
    dom1="${_DOMINANT[0]:-}"
    dom2="${_DOMINANT[1]:-}"
    dom3="${_DOMINANT[2]:-}"

    if [[ -n "$dom1" ]]; then
        info "Dominant colors: #$dom1${dom2:+, #$dom2}${dom3:+, #$dom3}"
        # Smart neutral detection from dominant color:
        # If the DOMINANT color is nearly achromatic (sat < 0.10), the wallpaper
        # has no meaningful hue to anchor a vibrant palette — use neutral.
        if [[ "$SCHEME_TYPE" == "scheme-vibrant" || "$SCHEME_TYPE" == "scheme-expressive" ]]; then
            _dom_sat=$(hex_saturation "$dom1")
            if awk -v s="$_dom_sat" 'BEGIN{exit !(s+0 < 0.10)}'; then
                info "Dominant color is achromatic → overriding to scheme-neutral"
                SCHEME_TYPE="scheme-neutral"
            fi
        fi
    else
        # No chromatic colors extracted — image is essentially grayscale
        if [[ "$SCHEME_TYPE" == "scheme-vibrant" || "$SCHEME_TYPE" == "scheme-expressive" ]]; then
            info "No chromatic colors found → overriding to scheme-neutral"
            SCHEME_TYPE="scheme-neutral"
        fi
    fi

    # Secondary check: if dominant is ok but overall image saturation is very low,
    # still fall back to neutral. Only apply this when no chromatic dominant colors
    # were found — if we DID find chromatic dominants (dom1 set), the dominant
    # saturation check above is already a reliable signal; don't second-guess it.
    if [[ -z "$dom1" ]] && [[ "$SCHEME_TYPE" == "scheme-vibrant" || "$SCHEME_TYPE" == "scheme-expressive" ]]; then
        _mean_sat=$(convert "$WALLPAPER" -colorspace HSL -channel S -separate +channel \
            -format "%[fx:mean]" info: 2>/dev/null) || _mean_sat="1"
        if awk -v s="$_mean_sat" 'BEGIN{exit !(s+0 < 0.20)}'; then
            info "Low mean saturation (${_mean_sat}) → overriding to scheme-neutral"
            SCHEME_TYPE="scheme-neutral"
        fi
    fi
else
    # ImageMagick unavailable — fall back to the original behavior
    # (matugen picks source color internally from the image)
    warn "ImageMagick not found; skipping dominant color extraction"
fi

info "Generating Material You colors ($SCHEME_TYPE) from: $(basename "$WALLPAPER")"

# ════════════════════════════════════════════════
#  Generate palette via matugen
# ════════════════════════════════════════════════
# When a dominant color was extracted we use `matugen color hex` — this is the
# same algorithm as `matugen image` but seeded from our histogram-derived color
# rather than matugen's internal pixel sampling. This gives superior results for
# wallpapers with complex backgrounds or mixed-color compositions.
#
# Safety fallback: if the color-hex path fails for any reason, we retry with the
# classic `image --source-color-index 0` path that always worked before.

_run_matugen_color() {
    matugen -j hex -t "$SCHEME_TYPE" --contrast "$CONTRAST" \
        color hex "#${dom1}" 2>/dev/null
}

_run_matugen_image() {
    matugen -j hex -t "$SCHEME_TYPE" --contrast "$CONTRAST" \
        image --source-color-index 0 "$WALLPAPER" 2>/dev/null
}

JSON=""
if [[ -n "$dom1" ]]; then
    JSON=$(_run_matugen_color) || true
    if [[ -z "$JSON" ]]; then
        warn "matugen color hex failed; falling back to image mode"
        JSON=$(_run_matugen_image) || true
    fi
else
    JSON=$(_run_matugen_image) || true
fi

[[ -n "$JSON" ]] || err "matugen failed — is the file a valid image? $WALLPAPER"

# Helper: extract a dark-scheme hex value, strip leading #
c() { echo "$JSON" | jq -r ".colors.${1}.dark.color" | sed 's/^#//'; }

# ════════════════════════════════════════════════
#  Extract Material You color roles
# ════════════════════════════════════════════════

# ── Primary palette (tone ~80 in dark mode) ──
primary=$(c "primary")
secondary=$(c "secondary")
tertiary=$(c "tertiary")

# ── Fixed variants (tone ~80–90, stable across light/dark and contrast levels) ──
primary_fixed=$(c "primary_fixed")
primary_fixed_dim=$(c "primary_fixed_dim")
secondary_fixed=$(c "secondary_fixed")
secondary_fixed_dim=$(c "secondary_fixed_dim")
tertiary_fixed=$(c "tertiary_fixed")
tertiary_fixed_dim=$(c "tertiary_fixed_dim")

# ── Chroma boosting + tone correction  (Smart Boost) ──────────────────────
# Applied only to accent roles. Surface / text / outline colors are left
# untouched — boosting those would break readability and contrast ratios.
primary=$(boost_color         "$primary")
secondary=$(boost_color       "$secondary")
tertiary=$(boost_color        "$tertiary")
primary_fixed=$(boost_color   "$primary_fixed")
secondary_fixed=$(boost_color "$secondary_fixed")
tertiary_fixed=$(boost_color  "$tertiary_fixed")
# *_fixed_dim stay close to their *_fixed peers after boosting them directly
primary_fixed_dim=$(boost_color   "$primary_fixed_dim")
secondary_fixed_dim=$(boost_color "$secondary_fixed_dim")
tertiary_fixed_dim=$(boost_color  "$tertiary_fixed_dim")

# ── Multi-accent blending from dominant colors  (Feature — Multi-Accent) ──
# Blend the 2nd and 3rd dominant wallpaper colors into matugen's secondary
# and tertiary at 20% weight. This nudges the palette toward colors that are
# actually visible in the image, improving diversity while keeping Material
# You's mathematical structure intact (80% matugen, 20% real-image color).
# The post-blend boost ensures blended colors remain vibrant.
if [[ -n "$dom2" ]]; then
    secondary=$(mix_hex "$secondary" "$dom2" 0.80)
    secondary=$(boost_color "$secondary")
fi
if [[ -n "$dom3" ]]; then
    tertiary=$(mix_hex "$tertiary" "$dom3" 0.80)
    tertiary=$(boost_color "$tertiary")
fi
# Seed *_fixed variants: blend dominant color into their fixed counterparts.
# These are stable-tone colors used as vivid highlights; grounding them in
# real image hues makes the theme feel more cohesive with the wallpaper.
if [[ -n "$dom1" ]]; then
    primary_fixed=$(mix_hex "$primary_fixed" "$dom1" 0.80)
    primary_fixed=$(boost_color "$primary_fixed")
fi
if [[ -n "$dom2" ]]; then
    secondary_fixed=$(mix_hex "$secondary_fixed" "$dom2" 0.80)
    secondary_fixed=$(boost_color "$secondary_fixed")
fi
if [[ -n "$dom3" ]]; then
    tertiary_fixed=$(mix_hex "$tertiary_fixed" "$dom3" 0.80)
    tertiary_fixed=$(boost_color "$tertiary_fixed")
fi

# ── Semantic ──
error=$(c "error")
error_container=$(c "error_container")

# ── Background & surfaces ──
background=$(c "background")
surface=$(c "surface")
surface_dim=$(c "surface_dim")
surface_bright=$(c "surface_bright")
surface_variant=$(c "surface_variant")
surface_container_lowest=$(c "surface_container_lowest")
surface_container_low=$(c "surface_container_low")
surface_container=$(c "surface_container")
surface_container_high=$(c "surface_container_high")
surface_container_highest=$(c "surface_container_highest")

# ── Text & outlines ──
on_surface=$(c "on_surface")
on_surface_variant=$(c "on_surface_variant")
outline=$(c "outline")
outline_variant=$(c "outline_variant")
inverse_primary=$(c "inverse_primary")
inverse_surface=$(c "inverse_surface")
scrim=$(c "scrim")

# ════════════════════════════════════════════════
#  Derived UI state colors  (Feature 2)
# ════════════════════════════════════════════════
# Material Design 3 uses alpha-based interaction layers. We approximate them
# as solid blended colors so apps without alpha support benefit too.
#
#  hover  ≈ primary at ~8%  in surface → mix(primary, surface_container, 0.85)
#  active ≈ primary at ~40% in surface → mix(primary, surface_container, 0.40)
#  dim    ≈ primary toned down         → mix(primary, surface_container, 0.70)

primary_hover=$(mix_hex  "$primary"   "$surface_container" 0.85)
primary_active=$(mix_hex "$primary"   "$surface_container" 0.40)
primary_dim=$(mix_hex    "$primary"   "$surface_container" 0.70)

secondary_hover=$(mix_hex  "$secondary" "$surface_container" 0.85)
secondary_active=$(mix_hex "$secondary" "$surface_container" 0.40)

# ── Background tint  (Feature 3) ──
# Android subtly tints the background toward the primary hue (≈1% primary).
# This adds warmth and cohesion — almost imperceptible but noticeable A/B.
background_tinted=$(mix_hex "$surface" "$primary" 0.99)

# ════════════════════════════════════════════════
#  Terminal color harmonization  (Feature 5)
# ════════════════════════════════════════════════
# ANSI terminal colors generated from standard semantic hues, then harmonized
# toward the wallpaper's primary accent at HARMONY_FACTOR=0.8 (20% hue shift).
#
# This preserves red=error / green=success / yellow=warning semantics while
# tying the terminal palette to the wallpaper's dominant color — matching how
# Material Design 3 harmonizes colors in Android's dynamic theming.
#
# Achromatic entries (black/gray/white) use Material surface roles directly.
# S/L levels for dark-background terminals:
#   Normal  (colors 1-6) : S=0.65, L=0.55 — visible but not harsh
#   Bright  (colors 9-14): S=0.72, L=0.70 — lifted for emphasis

HARMONY_FACTOR="0.8"

# Achromatic — no harmonization, use Material surface roles directly
term_bg="$surface"
term_fg="$on_surface"
term_color0="$surface"                # normal black   → window background
term_color7="$on_surface_variant"     # normal white   → muted text
term_color8="$surface_container_high" # bright black   → UI container level
term_color15="$on_surface"            # bright white   → primary text

# Chromatic normal colors — ANSI semantic hue → harmonize toward primary
term_color1=$(harmonize_hex "$(hsl_to_hex   5 0.65 0.55)" "$primary" "$HARMONY_FACTOR")  # red
term_color2=$(harmonize_hex "$(hsl_to_hex 130 0.55 0.52)" "$primary" "$HARMONY_FACTOR")  # green
term_color3=$(harmonize_hex "$(hsl_to_hex  45 0.70 0.58)" "$primary" "$HARMONY_FACTOR")  # yellow
term_color4=$(harmonize_hex "$(hsl_to_hex 220 0.65 0.55)" "$primary" "$HARMONY_FACTOR")  # blue
term_color5=$(harmonize_hex "$(hsl_to_hex 290 0.55 0.55)" "$primary" "$HARMONY_FACTOR")  # magenta
term_color6=$(harmonize_hex "$(hsl_to_hex 175 0.55 0.50)" "$primary" "$HARMONY_FACTOR")  # cyan

# Chromatic bright colors — same hues, higher L for the "bright" effect
term_color9=$(harmonize_hex  "$(hsl_to_hex   5 0.75 0.70)" "$primary" "$HARMONY_FACTOR")  # bright red
term_color10=$(harmonize_hex "$(hsl_to_hex 130 0.65 0.68)" "$primary" "$HARMONY_FACTOR")  # bright green
term_color11=$(harmonize_hex "$(hsl_to_hex  45 0.80 0.72)" "$primary" "$HARMONY_FACTOR")  # bright yellow
term_color12=$(harmonize_hex "$(hsl_to_hex 220 0.75 0.70)" "$primary" "$HARMONY_FACTOR")  # bright blue
term_color13=$(harmonize_hex "$(hsl_to_hex 290 0.65 0.70)" "$primary" "$HARMONY_FACTOR")  # bright magenta
term_color14=$(harmonize_hex "$(hsl_to_hex 175 0.65 0.68)" "$primary" "$HARMONY_FACTOR")  # bright cyan

# ════════════════════════════════════════════════
#  COLORS array — template substitution map
# ════════════════════════════════════════════════
# Templates (waybar, kitty, rofi, mako, hyprlock) use {{varname}} syntax with
# catppuccin-style names. We keep those names here so templates never need
# to change. The generated theme.conf has BOTH Material roles AND these aliases.
#
# Material You tone scale for dark mode (approximate):
#   tone ~90  primary_fixed / secondary_fixed / tertiary_fixed  → vivid highlight
#   tone ~80  primary / secondary / tertiary / *_fixed_dim      → standard accent
#   tone ~30  *_container                                        → dark bg ONLY
#   tone ~6   surface / surface_dim                             → window bg

declare -A COLORS

# ── Standard accents ──
COLORS[blue]="$primary"             # tone ~80, main accent
COLORS[mauve]="$tertiary"           # tone ~80, alt hue
COLORS[lavender]="$secondary"       # tone ~80, complementary
COLORS[sapphire]="$primary_fixed_dim"   # stable tone ~80
COLORS[sky]="$secondary_fixed_dim"      # stable tone ~80
COLORS[teal]="$tertiary_fixed_dim"      # stable tone ~80

# ── Vivid highlights (tone ~90, contrast-stable) ──
COLORS[rosewater]="$primary_fixed"
COLORS[flamingo]="$secondary_fixed"
COLORS[pink]="$tertiary_fixed"
COLORS[peach]="$tertiary_fixed"
COLORS[yellow]="$primary_fixed"
COLORS[green]="$secondary_fixed"

# ── Semantic ──
COLORS[red]="$error"
COLORS[maroon]="$error_container"

# ── Text hierarchy ──
COLORS[text]="$on_surface"
COLORS[on_surface_variant]="$on_surface_variant"
COLORS[subtext1]="$on_surface_variant"
COLORS[subtext0]="$outline"

# ── Surface stack (darkest → brightest) ──
COLORS[crust]="$surface_container_lowest"
COLORS[mantle]="$surface_dim"
COLORS[base]="$surface"
COLORS[surface0]="$surface_container_low"
COLORS[surface1]="$surface_container"
COLORS[surface2]="$surface_container_high"
COLORS[overlay0]="$surface_container_highest"
COLORS[overlay1]="$outline_variant"
COLORS[overlay2]="$outline"

# ════════════════════════════════════════════════
#  Apply templates
# ════════════════════════════════════════════════

apply_template() {
    local tpl="$1" out="$2" theme_name="$3"
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

THEME_NAME="material-you"

if [[ "$UPDATE_WAYBAR_STYLE" == "1" ]]; then
    apply_template "$CONFIGS_DIR/waybar/style.css.tpl"   "$WAYBAR_CONF/style.css"   "$THEME_NAME"
    success "  waybar style updated"
else
    info "  waybar style preserved (ANAND_DOTS_UPDATE_WAYBAR_STYLE=0)"
fi

apply_template "$CONFIGS_DIR/rofi/colors.rasi.tpl"   "$ROFI_CONF/colors.rasi"   "$THEME_NAME"
success "  rofi colors updated"

apply_template "$CONFIGS_DIR/mako/config.tpl"        "$MAKO_CONF/config"        "$THEME_NAME"
success "  mako config updated"

apply_template "$CONFIGS_DIR/kitty/kitty.conf.tpl"   "$KITTY_CONF/kitty.conf"   "$THEME_NAME"
success "  kitty config updated"

apply_template "$CONFIGS_DIR/hypr/hyprlock.conf.tpl" "$HYPR_CONF/hyprlock.conf" "$THEME_NAME"
success "  hyprlock config updated"

# ════════════════════════════════════════════════
#  Write theme.conf for Hyprland
# ════════════════════════════════════════════════
# Structured in five sections:
#   1. Full Material You role variables (primary, surface, etc.)
#   2. Derived interaction-state colors (hover, active, tinted bg)
#   3. Extended accent palette: $accent1–$accent9  (Feature 4)
#   4. Terminal harmony palette: $term_bg / $term_fg / $term_color0–15  (Feature 5)
#   5. Catppuccin-style compatibility aliases  (Feature 6)

DYNAMIC_THEME="$HYPR_CONF/theme.conf"
[[ -L "$DYNAMIC_THEME" ]] && rm "$DYNAMIC_THEME"
{
cat <<EOF
# ╔══════════════════════════════════════════════╗
# ║  Material You — $(basename "$WALLPAPER")
# ║  Scheme: $SCHEME_TYPE | Contrast: $CONTRAST
# ║  Dominant: ${dom1:+#$dom1}${dom2:+ #$dom2}${dom3:+ #$dom3}
# ╚══════════════════════════════════════════════╝

# ── Primary palette ─────────────────────────────
\$primary                   = rgb($primary)
\$secondary                 = rgb($secondary)
\$tertiary                  = rgb($tertiary)

# ── Fixed variants (tone ~80-90, contrast-stable) ─
\$primary_fixed             = rgb($primary_fixed)
\$primary_fixed_dim         = rgb($primary_fixed_dim)
\$secondary_fixed           = rgb($secondary_fixed)
\$secondary_fixed_dim       = rgb($secondary_fixed_dim)
\$tertiary_fixed            = rgb($tertiary_fixed)
\$tertiary_fixed_dim        = rgb($tertiary_fixed_dim)

# ── Background & surfaces ───────────────────────
\$background                = rgb($background)
\$background_tinted         = rgb($background_tinted)
\$surface                   = rgb($surface)
\$surface_dim               = rgb($surface_dim)
\$surface_bright            = rgb($surface_bright)
\$surface_variant           = rgb($surface_variant)
\$surface_container_lowest  = rgb($surface_container_lowest)
\$surface_container_low     = rgb($surface_container_low)
\$surface_container         = rgb($surface_container)
\$surface_container_high    = rgb($surface_container_high)
\$surface_container_highest = rgb($surface_container_highest)

# ── Text & outlines ─────────────────────────────
\$on_surface                = rgb($on_surface)
\$on_surface_variant        = rgb($on_surface_variant)
\$outline                   = rgb($outline)
\$outline_variant           = rgb($outline_variant)
\$inverse_primary           = rgb($inverse_primary)
\$inverse_surface           = rgb($inverse_surface)
\$scrim                     = rgb($scrim)

# ── Semantic ────────────────────────────────────
\$error                     = rgb($error)
\$error_container           = rgb($error_container)

# ── Derived interaction states ──────────────────
\$primary_hover             = rgb($primary_hover)
\$primary_active            = rgb($primary_active)
\$primary_dim               = rgb($primary_dim)
\$secondary_hover           = rgb($secondary_hover)
\$secondary_active          = rgb($secondary_active)

# ── Accent palette  (Feature 4) ─────────────────
# Extended range for syntax highlighting, rainbow delimiters, etc.
#   accent1–3 : primary / secondary / tertiary        (tone ~80)
#   accent4–6 : *_fixed — vivid, contrast-stable      (tone ~90)
#   accent7–9 : *_fixed_dim — muted bright variants   (tone ~80)
\$accent1 = rgb($primary)
\$accent2 = rgb($secondary)
\$accent3 = rgb($tertiary)
\$accent4 = rgb($primary_fixed)
\$accent5 = rgb($secondary_fixed)
\$accent6 = rgb($tertiary_fixed)
\$accent7 = rgb($primary_fixed_dim)
\$accent8 = rgb($secondary_fixed_dim)
\$accent9 = rgb($tertiary_fixed_dim)

# ── Terminal harmony palette  (Feature 5) ───────
# ANSI colors harmonized toward the primary accent (factor=$HARMONY_FACTOR).
# Each semantic hue is shifted 20% toward the wallpaper's dominant color
# for visual cohesion while preserving recognizable meaning (red=error, etc.).
\$term_bg      = rgb($term_bg)
\$term_fg      = rgb($term_fg)
\$term_color0  = rgb($term_color0)
\$term_color1  = rgb($term_color1)
\$term_color2  = rgb($term_color2)
\$term_color3  = rgb($term_color3)
\$term_color4  = rgb($term_color4)
\$term_color5  = rgb($term_color5)
\$term_color6  = rgb($term_color6)
\$term_color7  = rgb($term_color7)
\$term_color8  = rgb($term_color8)
\$term_color9  = rgb($term_color9)
\$term_color10 = rgb($term_color10)
\$term_color11 = rgb($term_color11)
\$term_color12 = rgb($term_color12)
\$term_color13 = rgb($term_color13)
\$term_color14 = rgb($term_color14)
\$term_color15 = rgb($term_color15)

# ── Compatibility aliases  (Feature 6) ──────────
# Catppuccin-style names → Material roles.
# Existing hyprland.conf border / decoration references continue to work.
\$blue       = rgb($primary)
\$mauve      = rgb($tertiary)
\$lavender   = rgb($secondary)
\$sapphire   = rgb($primary_fixed_dim)
\$sky        = rgb($secondary_fixed_dim)
\$teal       = rgb($tertiary_fixed_dim)
\$rosewater  = rgb($primary_fixed)
\$flamingo   = rgb($secondary_fixed)
\$pink       = rgb($tertiary_fixed)
\$peach      = rgb($tertiary_fixed)
\$yellow     = rgb($primary_fixed)
\$green      = rgb($secondary_fixed)
\$red        = rgb($error)
\$maroon     = rgb($error_container)
\$text       = rgb($on_surface)
\$subtext1   = rgb($on_surface_variant)
\$subtext0   = rgb($outline)
\$crust      = rgb($surface_container_lowest)
\$mantle     = rgb($surface_dim)
\$base       = rgb($surface)
\$surface0   = rgb($surface_container_low)
\$surface1   = rgb($surface_container)
\$surface2   = rgb($surface_container_high)
\$overlay0   = rgb($surface_container_highest)
\$overlay1   = rgb($outline_variant)
\$overlay2   = rgb($outline)
EOF
} > "$DYNAMIC_THEME"
success "  hyprland theme.conf updated"

# ════════════════════════════════════════════════
#  Save state
# ════════════════════════════════════════════════

mkdir -p "$CACHE_DIR"
echo "$THEME_NAME"         > "$CACHE_DIR/current-theme"
echo "$USER_SCHEME_TYPE"   > "$CACHE_DIR/scheme-type"   # save user preference, not auto-override
echo "$WALLPAPER"          > "$CACHE_DIR/last-wallpaper"

# ════════════════════════════════════════════════
#  Reload services
# ════════════════════════════════════════════════

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
success "Material You ($SCHEME_TYPE) applied from: $(basename "$WALLPAPER")"
