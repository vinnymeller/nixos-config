from enum import Enum

from libqtile.config import Screen
from libqtile.core.manager import Qtile
from settings.bars import get_bar


class ScreenLayout(Enum):
    FAKE = 1
    REAL = 2


screen_layout = ScreenLayout.REAL


_fake_screens = [
    Screen(top=get_bar(), x=0, y=909, width=3840, height=2160),
    Screen(top=get_bar(main_bar=True), x=3840, y=909, width=3840, height=2160),
    Screen(top=get_bar(), x=7680, y=0, width=2160, height=3840),
]

_screens = [
    Screen(top=get_bar(main_bar=True)),
    Screen(top=get_bar()),
]


# Tons of todos with this garbage:
# - can I handle which screens have which groups after swapping in a smarter way?
# - can I avoid calling qtile.restart() to switch back to "REAL" screen layout?
#   - for some reason the bars dont get configured properly when I do it the same way as setting up the fake screens
def toggle_screen_layout(qtile: Qtile):
    global screen_layout
    match screen_layout:
        case ScreenLayout.FAKE:
            # delete the attr "fake_screens" from "qtile.config"
            del qtile.config.fake_screens

            screen_layout = ScreenLayout.REAL
            qtile.screens[0].set_group(qtile.groups_map["1"])
            qtile.screens[1].set_group(qtile.groups_map["2"])
            qtile.restart()
        case ScreenLayout.REAL:
            qtile.config.screens.clear()
            qtile.screens.clear()
            qtile.config.fake_screens = _fake_screens
            qtile.reconfigure_screens()
            screen_layout = ScreenLayout.FAKE
            qtile.screens[0].set_group(qtile.groups_map["3"])
            qtile.screens[1].set_group(qtile.groups_map["1"])
            qtile.screens[2].set_group(qtile.groups_map["2"])
