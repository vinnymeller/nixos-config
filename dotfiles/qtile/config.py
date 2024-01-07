from libqtile import layout
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy

from bars import get_bar

alt = "mod1"
gui = "mod4"
ctrl = "control"
shift = "shift"
cg = [ctrl, gui]
scg = [shift, ctrl, gui]
acg = [alt, ctrl, gui]
ascg = [alt, shift, ctrl, gui]
terminal = "kitty"


keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([gui], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([gui], "j", lazy.layout.down(), desc="Move focus down"),
    Key([gui], "k", lazy.layout.up(), desc="Move focus up"),
    Key([gui], "l", lazy.layout.right(), desc="Move focus to right"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(scg, "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key(
        scg,
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    # Key(scg, "j", lazy.layout.shuffle_down(), desc="Move window down"),
    # Key(scg, "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # toggle floating and fullscreen
    Key(scg, "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key(cg, "f", lazy.window.toggle_floating(), desc="Toggle floating"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key(ascg, "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key(ascg, "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key(ascg, "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key(ascg, "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key(
        acg,
        "h",
        lazy.layout.shrink_left(),
        desc="Grow window to the left",
    ),
    Key(
        acg,
        "l",
        lazy.layout.shrink_right(),
        desc="Grow window to the right",
    ),
    Key(acg, "j", lazy.layout.shrink_down(), desc="Grow window down"),
    Key(acg, "k", lazy.layout.shrink_up(), desc="Grow window up"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [alt, shift],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key(scg, "t", lazy.spawn(terminal), desc="Launch terminal"),
    Key(scg, "b", lazy.spawn("firefox"), desc="Launch firefox"),
    # Toggle between different layouts as defined below
    Key(cg, "l", lazy.next_layout(), desc="Toggle between layouts"),
    Key([gui], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(scg, "w", lazy.window.kill(), desc="Kill focused window"),
    Key(acg, "r", lazy.reload_config(), desc="Reload the config"),
    Key(acg, "q", lazy.shutdown(), desc="Shutdown Qtile"),
    # Key([alt], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key(scg, "r", lazy.spawn("rofi -show drun"), desc="Open rofi"),
    # keys for moving to monitors
    Key([gui], "1", lazy.to_screen(0), desc="Move focus to monitor 0"),
    Key([gui], "6", lazy.to_screen(0), desc="Move focus to monitor 0"),
    Key(
        [gui], "2", lazy.to_screen(2), desc="Move focus to monitor 1"
    ),  # monitors 2 and 1 switched because of how they are physically arranged
    Key(
        [gui], "7", lazy.to_screen(2), desc="Move focus to monitor 1"
    ),  # how can i determine this programatically? TODO
    Key([gui], "3", lazy.to_screen(1), desc="Move focus to monitor 2"),
    Key([gui], "8", lazy.to_screen(1), desc="Move focus to monitor 2"),
    # keys for moving monitors sequentially
    Key(cg, "j", lazy.prev_screen(), desc="Move focus to prev monitor"),
    Key(cg, "k", lazy.next_screen(), desc="Move focus to prev monitor"),
    KeyChord(scg, "e", [Key([], "s", lazy.spawn("screenshot_to_clipboard"))]),
]

_group_names = [
    ("1", {"label": "term", "layout": "max"}),
    (
        "2",
        {
            "label": "code",
            "layout": "bsp",
            "spawn": "kitty",
            "init": True,
            "screen_affinity": 3,
        },
    ),
    (
        "3",
        {
            "label": "web",
            "layout": "max",
            # "spawn": "firefox", # this makes firefox want to sit in that group forever when spawning new ones. i guess just dont spawn it on startup?
            "init": True,
            "screen_affinity": 1,
        },
    ),
    ("4", {"label": "game", "layout": "max"}),
    (
        "5",
        {
            "label": "chat",
            "layout": "max",
            "spawn": "discord",
            "init": True,
            "screen_affinity": 2,
        },
    ),
    ("6", {"label": "work", "layout": "max"}),
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
                scg,
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = switch to & move focused window to group
            Key(
                cg,
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(i.name),
            ),
            Key(
                ascg,
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
