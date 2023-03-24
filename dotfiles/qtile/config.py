from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
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
    Key([win], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([win], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([win], "j", lazy.layout.down(), desc="Move focus down"),
    Key([win], "k", lazy.layout.up(), desc="Move focus up"),
    Key([win], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(
        [win, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"
    ),
    Key(
        [win, "shift"],
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    Key([win, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([win, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([win, ctrl], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([win, ctrl], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([win, ctrl], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([win, ctrl], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([win], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
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
    Key([alt], "b", lazy.spawn("firefox"), desc="Launch firefox"),
    # Toggle between different layouts as defined below
    Key([win, alt], "l", lazy.next_layout(), desc="Toggle between layouts"),
    Key([alt], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([win, ctrl], "r", lazy.reload_config(), desc="Reload the config"),
    Key([win, ctrl], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    # Key([alt], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key([alt], "r", lazy.spawn("rofi -show drun"), desc="Open rofi"),
]

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            Key(
                [win],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = switch to & move focused window to group
            Key(
                [win, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(i.name),
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod1 + shift + letter of group = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

layouts = [
    layout.Columns(border_focus_stack=["#d75f5f", "#8f3d3d"], border_width=4),
    layout.Max(),
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
follow_mouse_focus = True
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
