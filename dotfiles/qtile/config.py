from libqtile import layout
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy

from bars import get_bar

alt = "mod1"
win = "mod4"
ctrl = "control"
terminal = "kitty"


keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([alt], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([alt], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([alt], "j", lazy.layout.down(), desc="Move focus down"),
    Key([alt], "k", lazy.layout.up(), desc="Move focus up"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(
        [alt, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"
    ),
    Key(
        [alt, "shift"],
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    Key([alt, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([alt, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # toggle floating and fullscreen
    Key([alt], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([alt, "shift"], "f", lazy.window.toggle_floating(), desc="Toggle floating"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([win, ctrl], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([win, ctrl], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([win, ctrl], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([win, ctrl], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key(
        [win, ctrl, "shift"],
        "h",
        lazy.layout.shrink_left(),
        desc="Grow window to the left",
    ),
    Key(
        [win, ctrl, "shift"],
        "l",
        lazy.layout.shrink_right(),
        desc="Grow window to the right",
    ),
    Key([win, ctrl, "shift"], "j", lazy.layout.shrink_down(), desc="Grow window down"),
    Key([win, ctrl, "shift"], "k", lazy.layout.shrink_up(), desc="Grow window up"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [alt, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([alt], "t", lazy.spawn(terminal), desc="Launch terminal"),
    Key([alt], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([alt], "b", lazy.spawn("firefox"), desc="Launch firefox"),
    # Toggle between different layouts as defined below
    Key([win, alt], "l", lazy.next_layout(), desc="Toggle between layouts"),
    Key([alt], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([win, ctrl], "r", lazy.reload_config(), desc="Reload the config"),
    Key([win, ctrl], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    # Key([alt], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key([alt], "r", lazy.spawn("rofi -show drun"), desc="Open rofi"),
    # keys for moving to monitors
    Key([win], "1", lazy.to_screen(0), desc="Move focus to monitor 0"),
    Key([win], "6", lazy.to_screen(0), desc="Move focus to monitor 0"),
    Key([win], "2", lazy.to_screen(1), desc="Move focus to monitor 1"),
    Key([win], "7", lazy.to_screen(1), desc="Move focus to monitor 1"),
    Key([win], "3", lazy.to_screen(2), desc="Move focus to monitor 2"),
    Key([win], "8", lazy.to_screen(2), desc="Move focus to monitor 2"),
    # keys for moving monitors sequentially
    Key([win], "j", lazy.prev_screen(), desc="Move focus to prev monitor"),
    Key([win], "k", lazy.next_screen(), desc="Move focus to prev monitor"),
    KeyChord([alt], "e", [Key([], "s", lazy.spawn("screenshot_to_clipboard"))]),
]

_group_names = [
    ("1", {"label": "term", "layout": "bsp"}),
    (
        "2",
        {
            "label": "code",
            "layout": "bsp",
            "spawn": "kitty",
            "init": True,
        },
    ),
    (
        "3",
        {
            "label": "web",
            "layout": "columns",
            "spawn": "firefox",
            "init": True,
        },
    ),
    ("4", {"label": "game", "layout": "max"}),
    (
        "5",
        {
            "label": "chat",
            "layout": "columns",
            "spawn": "discord",
            "init": True,
        },
    ),
    ("6", {"label": "work", "layout": "columns"}),
    ("7", {}),
    ("8", {}),
    ("9", {}),
    ("0", {}),
]

groups = [Group(name, **kwargs) for name, kwargs in _group_names]

for i in groups:
    keys.extend(
        [
            Key(
                [alt],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = switch to & move focused window to group
            Key(
                [alt, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(i.name),
            ),
            Key(
                [alt, ctrl],
                i.name,
                lazy.window.togroup(i.name),
                desc="move focused window to group {}".format(i.name),
            ),
        ]
    )

border_globals = {
    "border_width": 3,
    "border_focus": "#881111",
    "border_on_single": True,
}
layouts = [
    layout.Columns(border_focus_stack=["#d75f5f", "#8f3d3d"], **border_globals),
    layout.Max(**border_globals),
    layout.Bsp(**border_globals),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="sans",
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(top=get_bar(main_bar=True)),
    Screen(top=get_bar()),
    Screen(top=get_bar()),
]

# Drag floating layouts.
mouse = [
    Drag(
        [ctrl],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [ctrl], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([ctrl], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = False  # true to focus window under mouse as it hovers around. false because my cats fkin move it while im typing and it fucks everything up
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
