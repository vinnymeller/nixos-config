from libqtile.config import Group

_group_names = [
    ("1", {"label": ""}),
    ("2", {"label": ""}),
    ("3", {"label": ""}),
    ("4", {"label": ""}),
    ("5", {"label": "\\eb99"}),
    ("6",),
    ("7",),
    ("8",),
    ("9",),
]

groups = [Group(name, **kwargs) for name, kwargs in _group_names]
