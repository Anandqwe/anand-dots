#!/usr/bin/env python3
# ╔══════════════════════════════════════════════════╗
# ║       anand-dots — Settings Application          ║
# ║  GTK4 / Libadwaita configuration GUI             ║
# ╚══════════════════════════════════════════════════╝

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gio, GLib

import os
import re
import subprocess
import sys

# ── Paths ────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
DOTFILES_DIR = os.path.dirname(SCRIPT_DIR)

HYPR_DIR = os.path.expanduser("~/.config/hypr")
KITTY_DIR = os.path.expanduser("~/.config/kitty")
MAKO_DIR = os.path.expanduser("~/.config/mako")

HYPRLAND_CONF = os.path.join(HYPR_DIR, "hyprland.conf")
ANIMATIONS_CONF = os.path.join(HYPR_DIR, "animations.conf")
MONITORS_CONF = os.path.join(HYPR_DIR, "monitors.conf")
HYPRIDLE_CONF = os.path.join(HYPR_DIR, "hypridle.conf")
KITTY_CONF = os.path.join(KITTY_DIR, "kitty.conf")
MAKO_CONF = os.path.join(MAKO_DIR, "config")

THEMES_DIR = os.path.join(DOTFILES_DIR, "themes")
THEME_SCRIPT = os.path.join(DOTFILES_DIR, "scripts", "theme.sh")


# ══════════════════════════════════════════════════════
#  Config Parsers
# ══════════════════════════════════════════════════════


class HyprConfig:
    """Parse and modify Hyprland-style config files (key = value with { } sections)."""

    def __init__(self, filepath):
        self.filepath = filepath
        self.lines = []
        self.load()

    def load(self):
        if os.path.exists(self.filepath):
            with open(self.filepath, "r") as f:
                self.lines = f.readlines()

    def _iter_with_sections(self):
        """Yield (line_index, stripped_line, section_stack) for each meaningful line."""
        section_stack = []
        for i, line in enumerate(self.lines):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                yield i, stripped, list(section_stack), "comment"
                continue
            if "{" in stripped and "=" not in stripped.split("{")[0]:
                name = stripped.split("{")[0].strip()
                section_stack.append(name)
                yield i, stripped, list(section_stack), "section_open"
                continue
            if stripped.startswith("}"):
                yield i, stripped, list(section_stack), "section_close"
                if section_stack:
                    section_stack.pop()
                continue
            if "=" in stripped:
                yield i, stripped, list(section_stack), "keyvalue"
            else:
                yield i, stripped, list(section_stack), "other"

    def get_value(self, key, section=None, subsection=None):
        for _i, stripped, stack, kind in self._iter_with_sections():
            if kind != "keyvalue":
                continue
            k, _, v = stripped.partition("=")
            k = k.strip()
            v = v.strip()
            if "#" in v:
                v = v[: v.index("#")].strip()

            if subsection:
                if (
                    len(stack) >= 2
                    and stack[-2] == section
                    and stack[-1] == subsection
                    and k == key
                ):
                    return v
            elif section:
                if stack and stack[-1] == section and k == key:
                    return v
            else:
                if not stack and k == key:
                    return v
        return None

    def set_value(self, key, value, section=None, subsection=None):
        for i, stripped, stack, kind in self._iter_with_sections():
            if kind != "keyvalue":
                continue
            k = stripped.split("=")[0].strip()
            match = False
            if subsection:
                match = (
                    len(stack) >= 2
                    and stack[-2] == section
                    and stack[-1] == subsection
                    and k == key
                )
            elif section:
                match = stack and stack[-1] == section and k == key
            else:
                match = not stack and k == key

            if match:
                indent = len(self.lines[i]) - len(self.lines[i].lstrip())
                comment = ""
                val_part = stripped.split("=", 1)[1]
                if "#" in val_part:
                    ci = val_part.index("#")
                    comment = "  " + val_part[ci:].strip()
                self.lines[i] = f"{' ' * indent}{key} = {value}{comment}\n"
                return True
        return False

    def get_env(self, var_name):
        for line in self.lines:
            s = line.strip()
            if s.startswith(f"env = {var_name},") or s.startswith(f"env={var_name},"):
                parts = s.split(",", 1)
                if len(parts) >= 2:
                    return parts[1].strip()
        return None

    def set_env(self, var_name, value):
        for i, line in enumerate(self.lines):
            s = line.strip()
            if s.startswith(f"env = {var_name},") or s.startswith(f"env={var_name},"):
                indent = len(line) - len(line.lstrip())
                self.lines[i] = f"{' ' * indent}env = {var_name},{value}\n"
                return True
        return False

    def save(self):
        with open(self.filepath, "w") as f:
            f.writelines(self.lines)


class IniConfig:
    """Parse and modify INI-style configs (mako: key=value, no spaces around =)."""

    def __init__(self, filepath):
        self.filepath = filepath
        self.lines = []
        self.load()

    def load(self):
        if os.path.exists(self.filepath):
            with open(self.filepath, "r") as f:
                self.lines = f.readlines()

    def get_value(self, key, section=None):
        current_section = None
        in_target = section is None
        for line in self.lines:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if stripped.startswith("["):
                current_section = stripped
                in_target = (current_section == section) if section else False
                continue
            if section is None and current_section is not None:
                continue
            if "=" in stripped and in_target:
                k, _, v = stripped.partition("=")
                if k.strip() == key:
                    return v.strip()
        return None

    def set_value(self, key, value, section=None):
        current_section = None
        in_target = section is None
        for i, line in enumerate(self.lines):
            stripped = line.strip()
            if stripped.startswith("["):
                current_section = stripped
                in_target = (current_section == section) if section else False
                continue
            if section is None and current_section is not None:
                continue
            if "=" in stripped and in_target:
                k = stripped.split("=")[0].strip()
                if k == key:
                    self.lines[i] = f"{key}={value}\n"
                    return True
        return False

    def save(self):
        with open(self.filepath, "w") as f:
            f.writelines(self.lines)


class HyprIdleConfig:
    """Parse and modify hypridle listener blocks."""

    def __init__(self, filepath):
        self.filepath = filepath
        self.lines = []
        self.load()

    def load(self):
        if os.path.exists(self.filepath):
            with open(self.filepath, "r") as f:
                self.lines = f.readlines()

    def get_timeouts(self):
        timeouts = []
        in_listener = False
        timeout = on_timeout = on_resume = None
        comment = None
        for line in self.lines:
            stripped = line.strip()
            if stripped.startswith("# ──") and not in_listener:
                comment = stripped.lstrip("# ").strip("─ ").strip()
            if "listener" in stripped and "{" in stripped:
                in_listener = True
                timeout = on_timeout = on_resume = None
                continue
            if in_listener:
                if stripped.startswith("}"):
                    timeouts.append(
                        {
                            "timeout": int(timeout) if timeout else 0,
                            "on_timeout": on_timeout or "",
                            "on_resume": on_resume or "",
                            "comment": comment or "",
                        }
                    )
                    in_listener = False
                    comment = None
                elif "=" in stripped:
                    k, _, v = stripped.partition("=")
                    k, v = k.strip(), v.strip()
                    if "#" in v:
                        v = v[: v.index("#")].strip()
                    if k == "timeout":
                        timeout = v
                    elif k == "on-timeout":
                        on_timeout = v
                    elif k == "on-resume":
                        on_resume = v
        return timeouts

    def set_timeout(self, index, seconds):
        listener_idx = -1
        in_listener = False
        for i, line in enumerate(self.lines):
            stripped = line.strip()
            if "listener" in stripped and "{" in stripped:
                listener_idx += 1
                in_listener = True
                continue
            if in_listener and stripped.startswith("}"):
                in_listener = False
                continue
            if in_listener and listener_idx == index and "=" in stripped:
                k = stripped.split("=")[0].strip()
                if k == "timeout":
                    indent = len(line) - len(line.lstrip())
                    comment = ""
                    val_part = stripped.split("=", 1)[1]
                    if "#" in val_part:
                        ci = val_part.index("#")
                        comment = "  " + val_part[ci:].strip()
                    self.lines[i] = f"{' ' * indent}timeout = {seconds}{comment}\n"
                    return True
        return False

    def save(self):
        with open(self.filepath, "w") as f:
            f.writelines(self.lines)


# ══════════════════════════════════════════════════════
#  UI Helpers
# ══════════════════════════════════════════════════════


def _fmt(val, digits):
    return str(int(val)) if digits == 0 else f"{val:.{digits}f}"


def make_scale_row(title, subtitle, value, min_val, max_val, step, digits=0, marks=None):
    # Adw.PreferencesRow has no activatable-widget click overlay, so
    # the Scale and SpinButton inside can receive focus/input directly.
    row = Adw.PreferencesRow()
    row.set_focusable(False)

    outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    outer.set_margin_top(10)
    outer.set_margin_bottom(10)
    outer.set_margin_start(16)
    outer.set_margin_end(16)

    title_lbl = Gtk.Label(label=title, xalign=0)
    title_lbl.add_css_class("heading")

    sub_lbl = Gtk.Label(label=subtitle, xalign=0)
    sub_lbl.set_wrap(True)
    sub_lbl.set_max_width_chars(70)
    sub_lbl.set_lines(3)
    sub_lbl.add_css_class("caption")
    sub_lbl.add_css_class("dim-label")

    adj = Gtk.Adjustment(
        value=value,
        lower=min_val,
        upper=max_val,
        step_increment=step,
        page_increment=step * 5,
    )

    scale = Gtk.Scale(adjustment=adj, orientation=Gtk.Orientation.HORIZONTAL)
    scale.set_hexpand(True)
    scale.set_digits(digits)
    scale.set_draw_value(False)
    if marks:
        for m in marks:
            scale.add_mark(m, Gtk.PositionType.BOTTOM, None)

    spinner = Gtk.SpinButton(adjustment=adj, climb_rate=0.1, digits=digits)
    spinner.set_width_chars(7)
    spinner.set_numeric(False)   # allow free typing; SpinButton validates on commit

    hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
    hbox.set_margin_top(4)
    hbox.append(scale)
    hbox.append(spinner)

    outer.append(title_lbl)
    outer.append(sub_lbl)
    outer.append(hbox)

    row.set_child(outer)
    row._adjustment = adj
    return row


def make_switch_row(title, subtitle, active):
    row = Adw.ActionRow(title=title, subtitle=subtitle)
    row.set_subtitle_lines(3)
    switch = Gtk.Switch()
    switch.set_active(active)
    switch.set_valign(Gtk.Align.CENTER)
    row.add_suffix(switch)
    row.set_activatable_widget(switch)
    row._switch = switch
    return row


def make_combo_row(title, subtitle, options, active_id):
    row = Adw.ActionRow(title=title, subtitle=subtitle)
    row.set_subtitle_lines(3)
    string_list = Gtk.StringList()
    for opt in options:
        string_list.append(opt)
    dropdown = Gtk.DropDown(model=string_list)
    dropdown.set_valign(Gtk.Align.CENTER)
    for i, opt in enumerate(options):
        if opt == active_id:
            dropdown.set_selected(i)
            break
    row.add_suffix(dropdown)
    row._dropdown = dropdown
    row._options = options
    return row


def make_entry_row(title, subtitle, text):
    row = Adw.ActionRow(title=title, subtitle=subtitle)
    row.set_subtitle_lines(3)
    entry = Gtk.Entry()
    entry.set_text(text or "")
    entry.set_valign(Gtk.Align.CENTER)
    entry.set_width_chars(20)
    row.add_suffix(entry)
    row._entry = entry
    return row


# ══════════════════════════════════════════════════════
#  Main Window
# ══════════════════════════════════════════════════════


class SettingsWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_title("anand-dots Settings")
        self.set_default_size(1050, 720)
        self.load_configs()
        self.build_ui()

    # ── Load configs ────────────────────────────────
    def load_configs(self):
        self.hypr = HyprConfig(HYPRLAND_CONF)
        self.anims = HyprConfig(ANIMATIONS_CONF)
        self.monitors = HyprConfig(MONITORS_CONF)
        self.idle = HyprIdleConfig(HYPRIDLE_CONF)
        self.mako = IniConfig(MAKO_CONF)

    # ── Build UI ────────────────────────────────────
    def build_ui(self):
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        # Header bar
        header = Adw.HeaderBar()
        header.set_title_widget(Gtk.Label(label="Settings"))

        apply_btn = Gtk.Button(label="Apply")
        apply_btn.add_css_class("suggested-action")
        apply_btn.connect("clicked", self.on_apply)
        header.pack_end(apply_btn)

        outer.append(header)

        # Content area
        content = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        content.set_vexpand(True)

        # Sidebar
        sidebar_scroll = Gtk.ScrolledWindow()
        sidebar_scroll.set_size_request(230, -1)
        sidebar_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        self.sidebar = Gtk.ListBox()
        self.sidebar.add_css_class("navigation-sidebar")
        self.sidebar.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.sidebar.connect("row-selected", self._on_sidebar)
        sidebar_scroll.set_child(self.sidebar)

        # Stack
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(150)
        self.stack.set_hexpand(True)
        self.stack.set_vexpand(True)

        content.append(sidebar_scroll)
        content.append(Gtk.Separator(orientation=Gtk.Orientation.VERTICAL))
        content.append(self.stack)
        outer.append(content)

        self.toast_overlay = Adw.ToastOverlay()
        self.toast_overlay.set_child(outer)
        self.set_content(self.toast_overlay)

        # Pages
        pages = [
            ("general", "General", "preferences-system-symbolic"),
            ("appearance", "Appearance", "applications-graphics-symbolic"),
            ("animations", "Animations", "view-reveal-symbolic"),
            ("theme", "Theme", "preferences-color-symbolic"),
            ("monitor", "Monitor", "video-display-symbolic"),
            ("input", "Input", "input-keyboard-symbolic"),
            ("idle", "Idle & Lock", "system-lock-screen-symbolic"),
            ("terminal", "Terminal", "utilities-terminal-symbolic"),
            ("notifications", "Notifications", "preferences-system-notifications-symbolic"),
        ]

        builders = {
            "general": self._page_general,
            "appearance": self._page_appearance,
            "animations": self._page_animations,
            "theme": self._page_theme,
            "monitor": self._page_monitor,
            "input": self._page_input,
            "idle": self._page_idle,
            "terminal": self._page_terminal,
            "notifications": self._page_notifications,
        }

        for pid, title, icon in pages:
            # sidebar row
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            for m in ("top", "bottom", "start", "end"):
                getattr(row_box, f"set_margin_{m}")(8)
            row_box.append(Gtk.Image.new_from_icon_name(icon))
            lbl = Gtk.Label(label=title)
            lbl.set_halign(Gtk.Align.START)
            lbl.set_hexpand(True)
            row_box.append(lbl)
            lr = Gtk.ListBoxRow()
            lr.set_child(row_box)
            lr._page_id = pid
            self.sidebar.append(lr)

            # page content
            scrolled = Gtk.ScrolledWindow()
            scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            clamp = Adw.Clamp()
            clamp.set_maximum_size(800)
            for m in (24,):
                clamp.set_margin_top(m)
                clamp.set_margin_bottom(m)
                clamp.set_margin_start(m)
                clamp.set_margin_end(m)
            clamp.set_child(builders[pid]())
            scrolled.set_child(clamp)
            self.stack.add_named(scrolled, pid)

        self.sidebar.select_row(self.sidebar.get_row_at_index(0))

    def _on_sidebar(self, _lb, row):
        if row:
            self.stack.set_visible_child_name(row._page_id)

    # ════════════════════════════════════════════════
    #  Page Builders
    # ════════════════════════════════════════════════

    def _page_general(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        # ── Gaps ──
        g = Adw.PreferencesGroup(
            title="Gaps",
            description="Control spacing between windows and screen edges",
        )
        v = int(self.hypr.get_value("gaps_in", "general") or 4)
        self.r_gaps_in = make_scale_row(
            "Inner Gaps",
            "Space between adjacent tiled windows in pixels.\n"
            "0 = windows touch each other · 4-8 = balanced · 15+ = very spacious (wastes screen)",
            v, 0, 30, 1, marks=[0, 5, 10, 15, 20, 25, 30],
        )
        g.add(self.r_gaps_in)

        v = int(self.hypr.get_value("gaps_out", "general") or 8)
        self.r_gaps_out = make_scale_row(
            "Outer Gaps",
            "Space between windows and screen edges.\n"
            "0 = edge-to-edge · 8-12 = clean margin · 20+ = lots of desktop visible",
            v, 0, 50, 1, marks=[0, 10, 20, 30, 40, 50],
        )
        g.add(self.r_gaps_out)
        box.append(g)

        # ── Borders ──
        g = Adw.PreferencesGroup(title="Borders")
        v = int(self.hypr.get_value("border_size", "general") or 2)
        self.r_border = make_scale_row(
            "Border Thickness",
            "Window border width in pixels.\n"
            "0 = no border (hard to see active window) · 2 = subtle · 4+ = thick, eye-catching",
            v, 0, 5, 1, marks=[0, 1, 2, 3, 4, 5],
        )
        g.add(self.r_border)
        box.append(g)

        # ── Layout ──
        g = Adw.PreferencesGroup(
            title="Layout",
            description="How windows are arranged on screen",
        )
        v = self.hypr.get_value("layout", "general") or "dwindle"
        self.r_layout = make_combo_row(
            "Tiling Algorithm",
            "dwindle = recursive split (like bspwm, good for many windows)\n"
            "master = one big + stacked side panel (like dwm, good for coding)",
            ["dwindle", "master"], v,
        )
        g.add(self.r_layout)

        v = self.hypr.get_value("resize_on_border", "general") or "true"
        self.r_resize = make_switch_row(
            "Resize on Border",
            "Drag window borders/edges with the mouse to resize.\n"
            "If OFF, you can only resize with keyboard shortcuts.",
            v.lower() == "true",
        )
        g.add(self.r_resize)

        v = self.hypr.get_value("allow_tearing", "general") or "true"
        self.r_tearing = make_switch_row(
            "Allow Screen Tearing",
            "Reduces input latency in fullscreen games by skipping VSync.\n"
            "May cause horizontal line artifacts. Only affects fullscreen apps.",
            v.lower() == "true",
        )
        g.add(self.r_tearing)
        box.append(g)

        # ── Cursor ──
        g = Adw.PreferencesGroup(title="Cursor")
        v = int(self.hypr.get_env("XCURSOR_SIZE") or 24)
        self.r_cursor_size = make_combo_row(
            "Cursor Size",
            "Size of the mouse cursor in pixels.\n"
            "24 = default · 32 = larger for HiDPI · 48 = very large for accessibility",
            ["16", "24", "32", "48", "64"], str(v),
        )
        g.add(self.r_cursor_size)
        box.append(g)

        # ── Misc ──
        g = Adw.PreferencesGroup(title="Miscellaneous")
        v = self.hypr.get_value("mouse_move_enables_dpms", "misc") or "true"
        self.r_dpms_mouse = make_switch_row(
            "Mouse Wakes Display",
            "Moving the mouse turns on a monitor that was powered off by idle timeout.",
            v.lower() == "true",
        )
        g.add(self.r_dpms_mouse)

        v = self.hypr.get_value("key_press_enables_dpms", "misc") or "true"
        self.r_dpms_key = make_switch_row(
            "Keypress Wakes Display",
            "Pressing any key turns on a monitor that was powered off by idle timeout.",
            v.lower() == "true",
        )
        g.add(self.r_dpms_key)
        box.append(g)

        return box

    # ── Appearance ──────────────────────────────────
    def _page_appearance(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        # Rounding
        g = Adw.PreferencesGroup(title="Window Rounding")
        v = int(self.hypr.get_value("rounding", "decoration") or 10)
        self.r_rounding = make_scale_row(
            "Corner Radius",
            "Rounds the corners of every window.\n"
            "0 = sharp square · 10 = softly rounded · 20+ = pill-shaped bubbles",
            v, 0, 25, 1, marks=[0, 5, 10, 15, 20, 25],
        )
        g.add(self.r_rounding)
        box.append(g)

        # Opacity
        g = Adw.PreferencesGroup(
            title="Transparency",
            description="Window opacity (1.0 = fully opaque, lower = see-through)",
        )
        v = float(self.hypr.get_value("active_opacity", "decoration") or 0.95)
        self.r_active_op = make_scale_row(
            "Focused Window",
            "Opacity of the window you're working in.\n"
            "1.0 = solid · 0.9 = slight transparency · below 0.7 makes text hard to read",
            v, 0.3, 1.0, 0.05, digits=2, marks=[0.3, 0.5, 0.7, 0.8, 0.9, 1.0],
        )
        g.add(self.r_active_op)

        v = float(self.hypr.get_value("inactive_opacity", "decoration") or 0.85)
        self.r_inact_op = make_scale_row(
            "Background Windows",
            "Opacity of unfocused windows. Makes it obvious which window is active.\n"
            "1.0 = same as focused · 0.8 = subtle dim · below 0.6 = very transparent",
            v, 0.3, 1.0, 0.05, digits=2, marks=[0.3, 0.5, 0.7, 0.8, 0.9, 1.0],
        )
        g.add(self.r_inact_op)
        box.append(g)

        # Blur
        g = Adw.PreferencesGroup(
            title="Background Blur",
            description="Frosted-glass effect behind transparent windows",
        )
        v = self.hypr.get_value("enabled", "decoration", "blur") or "true"
        self.r_blur_on = make_switch_row(
            "Enable Blur",
            "Apply Gaussian blur behind windows. Beautiful but GPU-heavy.\n"
            "Disable if you experience lag or stuttering on lower-end hardware.",
            v.lower() == "true",
        )
        g.add(self.r_blur_on)

        v = int(self.hypr.get_value("size", "decoration", "blur") or 16)
        self.r_blur_size = make_scale_row(
            "Blur Size",
            "Radius of the blur kernel. Higher = more spread out / blurrier.\n"
            "3-5 = subtle haze · 10-16 = nice frosted glass · 20+ = heavy blur (GPU-hungry)",
            v, 1, 30, 1, marks=[1, 5, 10, 15, 20, 25, 30],
        )
        g.add(self.r_blur_size)

        v = int(self.hypr.get_value("passes", "decoration", "blur") or 3)
        self.r_blur_pass = make_scale_row(
            "Blur Passes",
            "Number of blur iterations. More = smoother quality but more GPU work.\n"
            "1 = rough · 2-3 = good quality · 4+ = diminishing returns, high GPU cost",
            v, 1, 6, 1, marks=[1, 2, 3, 4, 5, 6],
        )
        g.add(self.r_blur_pass)

        v = float(self.hypr.get_value("vibrancy", "decoration", "blur") or 0.25)
        self.r_vibrancy = make_scale_row(
            "Vibrancy",
            "Boosts color saturation through the blur.\n"
            "0 = neutral grey blur · 0.25 = subtle tint · 1.0 = vivid psychedelic colors",
            v, 0.0, 1.0, 0.05, digits=2,
        )
        g.add(self.r_vibrancy)
        box.append(g)

        # Shadow
        g = Adw.PreferencesGroup(
            title="Window Shadows",
            description="Drop shadows for depth and floating effect",
        )
        v = self.hypr.get_value("enabled", "decoration", "shadow") or "true"
        self.r_shadow_on = make_switch_row(
            "Enable Shadows",
            "Adds soft shadows under windows for a 3D floating look.\n"
            "Disable to save a small amount of GPU. Flat look without shadows.",
            v.lower() == "true",
        )
        g.add(self.r_shadow_on)

        v = int(self.hypr.get_value("range", "decoration", "shadow") or 32)
        self.r_shadow_range = make_scale_row(
            "Shadow Range",
            "How far the shadow extends from the window edge.\n"
            "5-10 = tight subtle shadow · 20-40 = medium floating · 60+ = large dramatic shadow",
            v, 1, 100, 1, marks=[1, 25, 50, 75, 100],
        )
        g.add(self.r_shadow_range)

        v = int(self.hypr.get_value("render_power", "decoration", "shadow") or 2)
        self.r_shadow_pow = make_scale_row(
            "Shadow Sharpness",
            "Controls shadow falloff curve.\n"
            "1 = soft wide gradient · 2 = natural · 3-4 = sharp defined edge",
            v, 1, 4, 1, marks=[1, 2, 3, 4],
        )
        g.add(self.r_shadow_pow)
        box.append(g)

        return box

    # ── Animations ──────────────────────────────────
    def _page_animations(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        g = Adw.PreferencesGroup(
            title="Animations",
            description="Enable or disable all visual transitions. Higher speed values = slower animation.",
        )
        v = self.anims.get_value("enabled", "animations") or "true"
        self.r_anim_on = make_switch_row(
            "Enable Animations",
            "Master switch. OFF = instant window changes (better performance).\n"
            "ON = smooth transitions between states (looks polished).",
            v.lower() == "true",
        )
        g.add(self.r_anim_on)
        box.append(g)

        g = Adw.PreferencesGroup(
            title="Window Animations",
            description="Effects when windows open, close, or move",
        )
        v = self._get_anim_speed("windows")
        self.r_anim_win = make_scale_row(
            "Window Open/Close Speed",
            "Speed value for window appear/disappear animations.\n"
            "1 = nearly instant snap · 3 = quick & snappy (default) · 7+ = slow dramatic",
            v, 1, 10, 1, marks=[1, 3, 5, 7, 10],
        )
        g.add(self.r_anim_win)
        box.append(g)

        g = Adw.PreferencesGroup(title="Workspace Animations")
        v = self._get_anim_speed("workspaces")
        self.r_anim_ws = make_scale_row(
            "Workspace Switch Speed",
            "Speed of the sliding animation when switching workspaces.\n"
            "1 = instant jump · 5-7 = smooth slide (default) · 10 = very slow cinematic",
            v, 1, 10, 1, marks=[1, 3, 5, 7, 10],
        )
        g.add(self.r_anim_ws)
        box.append(g)

        g = Adw.PreferencesGroup(title="Fade Animations")
        v = self._get_anim_speed("fade")
        self.r_anim_fade = make_scale_row(
            "Fade Speed",
            "Speed of opacity transitions (windows fading in/out).\n"
            "1 = instant · 3 = subtle quick fade · 8+ = slow dreamy",
            v, 1, 10, 1, marks=[1, 3, 5, 7, 10],
        )
        g.add(self.r_anim_fade)
        box.append(g)

        g = Adw.PreferencesGroup(title="Border Animations")
        v = self._get_anim_speed("border")
        self.r_anim_border = make_scale_row(
            "Border Color Speed",
            "Speed of border color gradient animation between active/inactive.\n"
            "1 = instant color change · 10 = smooth transition · 20 = very slow morph",
            v, 1, 20, 1, marks=[1, 5, 10, 15, 20],
        )
        g.add(self.r_anim_border)
        box.append(g)

        return box

    def _get_anim_speed(self, name):
        for line in self.anims.lines:
            s = line.strip()
            if s.startswith(f"animation = {name},") or s.startswith(f"animation = {name} ,"):
                parts = s.split(",")
                if len(parts) >= 3:
                    try:
                        return int(parts[2].strip())
                    except ValueError:
                        pass
        return 3

    def _set_anim_speed(self, name, speed):
        for i, line in enumerate(self.anims.lines):
            s = line.strip()
            if s.startswith(f"animation = {name},") or s.startswith(f"animation = {name} ,"):
                parts = s.split(",")
                if len(parts) >= 3:
                    parts[2] = f" {speed}"
                    indent = len(line) - len(line.lstrip())
                    self.anims.lines[i] = " " * indent + ",".join(parts) + "\n"
                    return True
        return False

    # ── Theme ───────────────────────────────────────
    def _page_theme(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        g = Adw.PreferencesGroup(
            title="Color Theme",
            description="Choose a color scheme applied across Hyprland, Waybar, Kitty, Rofi, and Mako",
        )

        themes = []
        if os.path.exists(THEMES_DIR):
            themes = sorted(
                f.replace(".conf", "")
                for f in os.listdir(THEMES_DIR)
                if f.endswith(".conf")
            )

        cache = os.path.expanduser("~/.cache/anand-dots/current-theme")
        current = ""
        if os.path.exists(cache):
            with open(cache) as f:
                current = f.read().strip()

        if themes:
            self.r_theme = make_combo_row(
                "Active Theme",
                "Switching themes regenerates Waybar CSS, Kitty colors, Rofi palette,\n"
                "Mako notification colors, and Hyprlock from templates.",
                themes, current,
            )
            g.add(self.r_theme)
        box.append(g)

        descs = {
            "catppuccin-mocha": ("Catppuccin Mocha", "Warm pastel colors on a dark base — the most popular community theme. Soft purples, pinks, and blues."),
            "dracula": ("Dracula", "Bold purple-accented dark theme with high contrast. Classic, vibrant, recognizable."),
            "gruvbox-dark": ("Gruvbox Dark", "Retro warm tones with earthy oranges and greens. Easy on the eyes for long coding sessions."),
            "nord": ("Nord", "Cool arctic blue palette. Clean, minimal, professional feel. Inspired by Nordic nature."),
            "tokyo-night": ("Tokyo Night", "Inspired by Tokyo citylights at night. Modern dark blues with vibrant accent colors."),
        }

        g = Adw.PreferencesGroup(title="Available Themes")
        for t in themes:
            if t in descs:
                title, desc = descs[t]
                row = Adw.ActionRow(title=title, subtitle=desc)
                row.set_subtitle_lines(3)
                row.add_prefix(Gtk.Image.new_from_icon_name("color-select-symbolic"))
                g.add(row)
        box.append(g)

        return box

    # ── Monitor ─────────────────────────────────────
    def _page_monitor(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        g = Adw.PreferencesGroup(
            title="Display Configuration",
            description="Resolution, refresh rate, and UI scaling. Must match your monitor's supported modes.",
        )

        res, rate, scale = "1920x1080", "60", "1.25"
        for line in self.monitors.lines:
            s = line.strip()
            if s.startswith("monitor") and "=" in s and not s.startswith("#"):
                parts = [p.strip() for p in s.split("=", 1)[1].split(",")]
                if len(parts) >= 2:
                    rp = parts[1]
                    if "@" in rp:
                        res, rate = rp.split("@", 1)
                    else:
                        res = rp
                if len(parts) >= 4:
                    scale = parts[3]
                break

        self.r_res = make_combo_row(
            "Resolution",
            "Pixel dimensions of your display. Higher = sharper but needs more GPU.\n"
            "Must be a mode your monitor supports (check with hyprctl monitors).",
            ["1366x768", "1920x1080", "2560x1080", "2560x1440", "3440x1440", "3840x2160"],
            res,
        )
        g.add(self.r_res)

        self.r_rate = make_combo_row(
            "Refresh Rate (Hz)",
            "How many times per second the screen redraws.\n"
            "60 = standard · 120-144 = smooth gaming · 240 = competitive. Must be monitor-supported.",
            ["60", "75", "90", "120", "144", "165", "240"], rate,
        )
        g.add(self.r_rate)

        self.r_scale = make_combo_row(
            "Display Scale",
            "UI element scaling factor.\n"
            "1.0 = native (small on HiDPI) · 1.25 = slightly larger · 2.0 = doubled (4K → 1080p-sized UI)",
            ["1.0", "1.25", "1.5", "1.75", "2.0"], scale,
        )
        g.add(self.r_scale)
        box.append(g)

        tip = Adw.PreferencesGroup()
        r = Adw.ActionRow(
            title="Tip",
            subtitle="Run  hyprctl monitors  in a terminal to see connected displays and their supported modes.",
        )
        r.add_prefix(Gtk.Image.new_from_icon_name("dialog-information-symbolic"))
        tip.add(r)
        box.append(tip)

        return box

    # ── Input ───────────────────────────────────────
    def _page_input(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        g = Adw.PreferencesGroup(title="Keyboard")
        v = self.hypr.get_value("kb_layout", "input") or "us"
        self.r_kb = make_entry_row(
            "Layout",
            "XKB keyboard layout code. Examples: us, gb, de, fr, es, ru.\n"
            "Multiple layouts (comma-separated): us,de — switch with Super+Space.",
            v,
        )
        g.add(self.r_kb)
        box.append(g)

        g = Adw.PreferencesGroup(title="Mouse")
        v = float(self.hypr.get_value("sensitivity", "input") or 0)
        self.r_sens = make_scale_row(
            "Sensitivity",
            "Mouse speed multiplier applied on top of system acceleration.\n"
            "-1.0 = slowest · 0 = default (no change) · 1.0 = fastest/most sensitive",
            v, -1.0, 1.0, 0.1, digits=1, marks=[-1.0, -0.5, 0, 0.5, 1.0],
        )
        g.add(self.r_sens)

        v = int(self.hypr.get_value("follow_mouse", "input") or 1)
        self.r_follow = make_combo_row(
            "Focus Follows Mouse",
            "0 = click to focus (like Windows) · 1 = focus on enter (like most tiling WMs)\n"
            "2 = loose follow · 3 = strict follow (focus changes even across monitors)",
            ["0", "1", "2", "3"], str(v),
        )
        g.add(self.r_follow)
        box.append(g)

        g = Adw.PreferencesGroup(title="Touchpad")
        v = self.hypr.get_value("natural_scroll", "input", "touchpad") or "true"
        self.r_natscroll = make_switch_row(
            "Natural Scrolling",
            "ON = scroll direction matches finger movement (like phones/macOS).\n"
            "OFF = traditional 'reverse' scroll (like classic PCs).",
            v.lower() == "true",
        )
        g.add(self.r_natscroll)
        box.append(g)

        return box

    # ── Idle & Lock ─────────────────────────────────
    def _page_idle(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        timeouts = self.idle.get_timeouts()

        g = Adw.PreferencesGroup(
            title="Idle Timeouts",
            description="Actions triggered after periods of inactivity (in minutes). 0 = disabled.\nOrder matters: each timeout must be longer than the previous one.",
        )

        labels = [
            ("Dim Screen", "Reduces brightness to minimum to save power. Screen stays on.\nMouse/key activity restores brightness immediately."),
            ("Lock Screen", "Activates hyprlock — requires your password to unlock.\nPrevents unauthorized access when you step away."),
            ("Turn Off Display", "Powers off monitor completely (DPMS off). Saves more energy.\nMouse movement or keypress turns it back on."),
            ("Suspend System", "Puts the computer into sleep/suspend mode to save maximum power.\nPress power button or open laptop lid to wake."),
        ]

        self.idle_rows = []
        for i, t in enumerate(timeouts):
            if i < len(labels):
                title, desc = labels[i]
            else:
                title, desc = f"Action {i+1}", t.get("comment", "")
            mins = t["timeout"] / 60
            row = make_scale_row(
                title,
                f"{desc}\nCurrent: {mins:.0f} min ({t['timeout']}s)",
                mins, 0, 120, 1,
                marks=[0, 5, 10, 15, 30, 60, 90, 120],
            )
            g.add(row)
            self.idle_rows.append(row)
        box.append(g)

        warn = Adw.PreferencesGroup()
        r = Adw.ActionRow(
            title="Order Requirement",
            subtitle="Timeouts must increase: Dim < Lock < Display Off < Suspend.\nExample: 8 min → 10 min → 11 min → 30 min. Breaking this order causes unexpected behavior.",
        )
        r.set_subtitle_lines(3)
        r.add_prefix(Gtk.Image.new_from_icon_name("dialog-warning-symbolic"))
        warn.add(r)
        box.append(warn)

        return box

    # ── Terminal ────────────────────────────────────
    def _page_terminal(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        g = Adw.PreferencesGroup(title="Font")
        v = self._kitty_get("font_family") or "JetBrainsMono Nerd Font"
        self.r_kfont = make_entry_row(
            "Font Family",
            "Monospace font for terminal text. Nerd Font variants recommended for icon support.\n"
            "Examples: JetBrainsMono Nerd Font, FiraCode Nerd Font, Hack Nerd Font",
            v,
        )
        g.add(self.r_kfont)

        v = float(self._kitty_get("font_size") or 12.0)
        self.r_kfsize = make_scale_row(
            "Font Size",
            "Text size in points.\n"
            "8-10 = compact (fits more text) · 12 = standard · 16+ = large (accessibility)",
            v, 6, 24, 0.5, digits=1, marks=[6, 8, 10, 12, 14, 16, 18, 20, 24],
        )
        g.add(self.r_kfsize)
        box.append(g)

        g = Adw.PreferencesGroup(title="Appearance")
        v = float(self._kitty_get("background_opacity") or 0.5)
        self.r_kop = make_scale_row(
            "Background Opacity",
            "Terminal background transparency.\n"
            "0.3 = very see-through · 0.5 = balanced (see wallpaper) · 1.0 = fully solid",
            v, 0.0, 1.0, 0.05, digits=2, marks=[0.0, 0.25, 0.5, 0.75, 1.0],
        )
        g.add(self.r_kop)

        v = int(self._kitty_get("window_padding_width") or 12)
        self.r_kpad = make_scale_row(
            "Window Padding",
            "Space between terminal text and window edges in pixels.\n"
            "0 = text at edges · 8-12 = comfortable · 20+ = lots of whitespace",
            v, 0, 40, 1, marks=[0, 5, 10, 15, 20, 30, 40],
        )
        g.add(self.r_kpad)
        box.append(g)

        g = Adw.PreferencesGroup(title="Cursor")
        v = self._kitty_get("cursor_shape") or "beam"
        self.r_kcursor = make_combo_row(
            "Cursor Shape",
            "beam = thin vertical line (modern, default)\n"
            "block = filled rectangle (classic terminal) · underline = flat bottom bar",
            ["beam", "block", "underline"], v,
        )
        g.add(self.r_kcursor)
        box.append(g)

        g = Adw.PreferencesGroup(title="Behavior")
        v = int(self._kitty_get("scrollback_lines") or 10000)
        self.r_kscroll = make_scale_row(
            "Scrollback Lines",
            "Lines of terminal history kept in memory.\n"
            "2000 = minimal · 10000 = good default · 50000+ = large buffer (uses more RAM)",
            v, 1000, 100000, 1000, marks=[1000, 10000, 25000, 50000, 100000],
        )
        g.add(self.r_kscroll)
        box.append(g)

        return box

    def _kitty_get(self, key):
        if not os.path.exists(KITTY_CONF):
            return None
        with open(KITTY_CONF) as f:
            for line in f:
                s = line.strip()
                if s.startswith("#") or not s:
                    continue
                parts = s.split(None, 1)
                if len(parts) >= 2 and parts[0] == key:
                    return parts[1].strip()
        return None

    def _kitty_set(self, key, value):
        if not os.path.exists(KITTY_CONF):
            return
        with open(KITTY_CONF) as f:
            lines = f.readlines()
        for i, line in enumerate(lines):
            s = line.strip()
            if s.startswith("#") or not s:
                continue
            parts = s.split(None, 1)
            if parts and parts[0] == key:
                lines[i] = f"{key} {value}\n"
                break
        with open(KITTY_CONF, "w") as f:
            f.writelines(lines)

    # ── Notifications ───────────────────────────────
    def _page_notifications(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        g = Adw.PreferencesGroup(
            title="Behavior",
            description="How notifications appear and auto-dismiss",
        )
        v = int(self.mako.get_value("default-timeout") or 5000)
        self.r_ntimeout = make_scale_row(
            "Display Duration (ms)",
            "How long each notification stays visible in milliseconds.\n"
            "3000 = 3 sec (quick glance) · 5000 = 5 sec (default) · 0 = stay until dismissed",
            v, 0, 30000, 500, marks=[0, 5000, 10000, 15000, 20000, 30000],
        )
        g.add(self.r_ntimeout)

        v = int(self.mako.get_value("max-visible") or 3)
        self.r_nmaxvis = make_scale_row(
            "Max Visible",
            "Maximum notifications shown at once. Excess queue up.\n"
            "1 = one at a time · 3 = balanced · 5+ = see many but can clutter screen",
            v, 1, 10, 1, marks=[1, 3, 5, 7, 10],
        )
        g.add(self.r_nmaxvis)

        v = self.mako.get_value("anchor") or "top-right"
        self.r_nanchor = make_combo_row(
            "Position",
            "Screen corner where notifications pop up.",
            ["top-right", "top-left", "top-center", "bottom-right", "bottom-left", "bottom-center"],
            v,
        )
        g.add(self.r_nanchor)
        box.append(g)

        g = Adw.PreferencesGroup(
            title="Appearance",
            description="Notification popup styling",
        )
        v = int(self.mako.get_value("width") or 350)
        self.r_nwidth = make_scale_row(
            "Width",
            "Popup width in pixels.\n"
            "250 = compact (short messages) · 350 = standard · 500+ = wide (long text)",
            v, 200, 600, 10, marks=[200, 300, 400, 500, 600],
        )
        g.add(self.r_nwidth)

        v = int(self.mako.get_value("border-size") or 2)
        self.r_nborder = make_scale_row(
            "Border Size",
            "Border thickness around notification box.\n"
            "0 = no border · 2 = subtle line · 4+ = thick frame",
            v, 0, 5, 1, marks=[0, 1, 2, 3, 4, 5],
        )
        g.add(self.r_nborder)

        v = int(self.mako.get_value("border-radius") or 8)
        self.r_nradius = make_scale_row(
            "Corner Radius",
            "Rounding of notification box corners.\n"
            "0 = sharp · 8 = softly rounded · 15+ = very round pill shape",
            v, 0, 20, 1, marks=[0, 5, 10, 15, 20],
        )
        g.add(self.r_nradius)

        v = int(self.mako.get_value("padding") or 12)
        self.r_npad = make_scale_row(
            "Padding",
            "Inner spacing between notification text and box edge.\n"
            "4 = tight · 12 = comfortable · 20+ = very spacious",
            v, 0, 30, 1, marks=[0, 5, 10, 15, 20, 25, 30],
        )
        g.add(self.r_npad)
        box.append(g)

        return box

    # ════════════════════════════════════════════════
    #  Save / Apply
    # ════════════════════════════════════════════════

    def on_apply(self, _btn):
        try:
            self._save_general()
            self._save_appearance()
            self._save_animations()
            self._save_theme()
            self._save_monitor()
            self._save_input()
            self._save_idle()
            self._save_terminal()
            self._save_notifications()
            self._reload()
            self.toast_overlay.add_toast(
                Adw.Toast(title="Settings applied and services reloaded")
            )
        except Exception as e:
            self.toast_overlay.add_toast(Adw.Toast(title=f"Error: {e}"))

    def _save_general(self):
        self.hypr.set_value("gaps_in", int(self.r_gaps_in._adjustment.get_value()), "general")
        self.hypr.set_value("gaps_out", int(self.r_gaps_out._adjustment.get_value()), "general")
        self.hypr.set_value("border_size", int(self.r_border._adjustment.get_value()), "general")
        idx = self.r_layout._dropdown.get_selected()
        self.hypr.set_value("layout", self.r_layout._options[idx], "general")
        self.hypr.set_value("resize_on_border", "true" if self.r_resize._switch.get_active() else "false", "general")
        self.hypr.set_value("allow_tearing", "true" if self.r_tearing._switch.get_active() else "false", "general")
        idx = self.r_cursor_size._dropdown.get_selected()
        csize = self.r_cursor_size._options[idx]
        self.hypr.set_env("XCURSOR_SIZE", csize)
        self.hypr.set_env("HYPRCURSOR_SIZE", csize)
        self.hypr.set_value("mouse_move_enables_dpms", "true" if self.r_dpms_mouse._switch.get_active() else "false", "misc")
        self.hypr.set_value("key_press_enables_dpms", "true" if self.r_dpms_key._switch.get_active() else "false", "misc")
        self.hypr.save()

    def _save_appearance(self):
        self.hypr.set_value("rounding", int(self.r_rounding._adjustment.get_value()), "decoration")
        self.hypr.set_value("active_opacity", f"{self.r_active_op._adjustment.get_value():.2f}", "decoration")
        self.hypr.set_value("inactive_opacity", f"{self.r_inact_op._adjustment.get_value():.2f}", "decoration")
        self.hypr.set_value("enabled", "true" if self.r_blur_on._switch.get_active() else "false", "decoration", "blur")
        self.hypr.set_value("size", int(self.r_blur_size._adjustment.get_value()), "decoration", "blur")
        self.hypr.set_value("passes", int(self.r_blur_pass._adjustment.get_value()), "decoration", "blur")
        self.hypr.set_value("vibrancy", f"{self.r_vibrancy._adjustment.get_value():.2f}", "decoration", "blur")
        self.hypr.set_value("enabled", "true" if self.r_shadow_on._switch.get_active() else "false", "decoration", "shadow")
        self.hypr.set_value("range", int(self.r_shadow_range._adjustment.get_value()), "decoration", "shadow")
        self.hypr.set_value("render_power", int(self.r_shadow_pow._adjustment.get_value()), "decoration", "shadow")
        self.hypr.save()

    def _save_animations(self):
        self.anims.set_value("enabled", "true" if self.r_anim_on._switch.get_active() else "false", "animations")
        ws = int(self.r_anim_win._adjustment.get_value())
        self._set_anim_speed("windows", ws)
        self._set_anim_speed("windowsIn", ws)
        self._set_anim_speed("windowsOut", ws)
        self._set_anim_speed("workspaces", int(self.r_anim_ws._adjustment.get_value()))
        self._set_anim_speed("fade", int(self.r_anim_fade._adjustment.get_value()))
        self._set_anim_speed("border", int(self.r_anim_border._adjustment.get_value()))
        self.anims.save()

    def _save_theme(self):
        if not hasattr(self, "r_theme"):
            return
        idx = self.r_theme._dropdown.get_selected()
        theme = self.r_theme._options[idx]
        if os.path.exists(THEME_SCRIPT):
            subprocess.Popen(
                ["bash", THEME_SCRIPT, theme],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

    def _save_monitor(self):
        res = self.r_res._options[self.r_res._dropdown.get_selected()]
        rate = self.r_rate._options[self.r_rate._dropdown.get_selected()]
        scale = self.r_scale._options[self.r_scale._dropdown.get_selected()]
        new_line = f"monitor = , {res}@{rate}, auto, {scale}\n"
        for i, line in enumerate(self.monitors.lines):
            s = line.strip()
            if s.startswith("monitor") and "=" in s and not s.startswith("#"):
                self.monitors.lines[i] = new_line
                break
        self.monitors.save()

    def _save_input(self):
        self.hypr.set_value("kb_layout", self.r_kb._entry.get_text().strip(), "input")
        self.hypr.set_value("sensitivity", f"{self.r_sens._adjustment.get_value():.1f}", "input")
        fm = self.r_follow._options[self.r_follow._dropdown.get_selected()]
        self.hypr.set_value("follow_mouse", fm, "input")
        self.hypr.set_value(
            "natural_scroll",
            "true" if self.r_natscroll._switch.get_active() else "false",
            "input", "touchpad",
        )
        self.hypr.save()

    def _save_idle(self):
        for i, row in enumerate(self.idle_rows):
            secs = int(row._adjustment.get_value() * 60)
            self.idle.set_timeout(i, secs)
        self.idle.save()

    def _save_terminal(self):
        self._kitty_set("font_family", self.r_kfont._entry.get_text().strip())
        self._kitty_set("font_size", f"{self.r_kfsize._adjustment.get_value():.1f}")
        self._kitty_set("background_opacity", f"{self.r_kop._adjustment.get_value():.2f}")
        self._kitty_set("window_padding_width", int(self.r_kpad._adjustment.get_value()))
        cur = self.r_kcursor._options[self.r_kcursor._dropdown.get_selected()]
        self._kitty_set("cursor_shape", cur)
        self._kitty_set("scrollback_lines", int(self.r_kscroll._adjustment.get_value()))

    def _save_notifications(self):
        self.mako.set_value("default-timeout", int(self.r_ntimeout._adjustment.get_value()))
        self.mako.set_value("max-visible", int(self.r_nmaxvis._adjustment.get_value()))
        anc = self.r_nanchor._options[self.r_nanchor._dropdown.get_selected()]
        self.mako.set_value("anchor", anc)
        self.mako.set_value("width", int(self.r_nwidth._adjustment.get_value()))
        self.mako.set_value("border-size", int(self.r_nborder._adjustment.get_value()))
        self.mako.set_value("border-radius", int(self.r_nradius._adjustment.get_value()))
        self.mako.set_value("padding", int(self.r_npad._adjustment.get_value()))
        self.mako.save()

    def _reload(self):
        try:
            subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=5)
        except Exception:
            pass
        try:
            subprocess.run(["pkill", "-x", "waybar"], capture_output=True, timeout=3)
            subprocess.Popen(["waybar"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass
        try:
            subprocess.run(["pkill", "-x", "mako"], capture_output=True, timeout=3)
            subprocess.Popen(["mako"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass
        try:
            subprocess.run(["pkill", "-USR1", "-x", "kitty"], capture_output=True, timeout=3)
        except Exception:
            pass


# ══════════════════════════════════════════════════════
#  Application
# ══════════════════════════════════════════════════════


class SettingsApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="dev.anand.dots.settings")

    def do_activate(self):
        win = SettingsWindow(application=self)
        win.present()


def main():
    app = SettingsApp()
    app.run(sys.argv)


if __name__ == "__main__":
    main()
