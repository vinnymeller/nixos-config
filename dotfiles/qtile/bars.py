from libqtile import bar, widget


def get_bar(main_bar=False):
    bar_items = [
        widget.CurrentLayout(),
        widget.GroupBox(disable_drag=True),
        widget.Prompt(),
        widget.WindowName(),
        widget.Chord(
            chords_colors={
                "launch": ("#ff0000", "#ffffff"),
            },
            name_transform=lambda name: name.upper(),
        ),
        widget.Pomodoro(),
        widget.Net(format="{down} \u2193\u2191 {up}"),
        widget.CPU(),
        widget.Memory(measure_mem="G"),
        widget.Systray() if main_bar else widget.Sep(),
        widget.Clock(format="%Y-%m-%d %a %I:%M %p"),
    ]
    return bar.Bar(bar_items, 24, border_width=0)
