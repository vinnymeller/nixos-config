---@module 'hl'
-- NOTE: This file is inlined into ~/.config/hypr/hyprland.lua by the Home
-- Manager Hyprland module (via extraConfig). Two globals are injected ahead of
-- it: `hl` (Hyprland's Lua API) and `NIX`, a table of Nix-owned values defined
-- in features/hyprland/default.nix (NIX.colors.*, NIX.features.*). Edit those
-- values in default.nix, not here. NIX's shape is typed in ./nix.meta.lua.

local filemanager = "nemo"

local god = "SUPER + CTRL + ALT + SHIFT"

local ml = "DP-2"

local mod = "SUPER"

local mr = "DP-1"

local terminal = "kitty"

hl.config({
	animations = {
		enabled = true,
	},
})

-- animation curves (hyprlang `bezier`): the 4 numbers are the two inner
-- control points of the cubic bezier.
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("md3_standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
hl.curve("crazyshot", { type = "bezier", points = { { 0.1, 1.5 }, { 0.76, 0.92 } } })
hl.curve("hyprnostretch", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.38, 0.04 }, { 1, 0.07 } } })
hl.curve("easeInOutCirc", { type = "bezier", points = { { 0.85, 0 }, { 0.15, 1 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.55 }, { 0.45, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("softAcDecel", { type = "bezier", points = { { 0.26, 0.26 }, { 0.15, 1 } } })
hl.curve("md2", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })

-- animations (hyprlang `animation = NAME, ONOFF, SPEED, CURVE[, STYLE]`).
-- `default` is a built-in curve.
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "md3_accel", style = "popin 60%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "fadeSwitch", enabled = false, speed = 1, bezier = "default" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.6, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 4.5, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "md3_decel", style = "slidevert" })

hl.bind(mod .. " + " .. "SPACE", hl.dsp.exec_cmd("rofi -show drun -show-icons"))

hl.bind(
	mod .. " + " .. "B",
	hl.dsp.exec_cmd("rofi -modi 'Chrome Profile':rofi-chrome-profile-launcher -show 'Chrome Profile'")
)

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "W", hl.dsp.exec_cmd("rofi -show window --show-icons"))

hl.bind(mod .. " + " .. "D", hl.dsp.exec_cmd(filemanager))

hl.bind(mod .. " + " .. "T", hl.dsp.exec_cmd("uwsm app -- " .. terminal))

hl.bind(mod .. " + " .. "RETURN", hl.dsp.exec_cmd(terminal))

hl.bind(mod .. " + " .. "V", hl.dsp.exec_cmd(terminal .. " --class clipse -e clipse"))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "S", hl.dsp.exec_cmd("hyprshot -m region output --clipboard-only"))

hl.bind(mod .. " + " .. "SHIFT + ALT" .. " + " .. "L", hl.dsp.exec_cmd("hyprlock"))

hl.bind(mod .. " + " .. "W", hl.dsp.window.close())

hl.bind(mod .. " + " .. "R", hl.dsp.window.float())

hl.bind(mod .. " + " .. "U", hl.dsp.focus({ urgent_or_last = true }))

hl.bind(mod .. " + " .. "TAB", hl.dsp.focus({ last = true }))

hl.bind(mod .. " + " .. "F", hl.dsp.window.fullscreen())

-- action = "toggle" restores the legacy hyprlang `fullscreenstate` behavior:
-- the Lua fullscreen_state dispatcher defaults to action = "set" (into the state
-- only), so without this SUPER+CTRL+F wouldn't toggle back out. See
-- LuaBindingsDispatchers.cpp: action 0=toggle, 1=set, 2=unset.
hl.bind(mod .. " + " .. "CTRL" .. " + " .. "F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))

hl.bind(mod .. " + " .. "P", hl.dsp.window.pin())

hl.bind(mod .. " + " .. "h", hl.dsp.focus({ direction = "left" }))

hl.bind(mod .. " + " .. "l", hl.dsp.focus({ direction = "right" }))

hl.bind(mod .. " + " .. "j", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + " .. "k", hl.dsp.focus({ direction = "up" }))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "h", hl.dsp.window.move({ direction = "left" }))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "l", hl.dsp.window.move({ direction = "right" }))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "j", hl.dsp.window.move({ direction = "down" }))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "k", hl.dsp.window.move({ direction = "up" }))

hl.bind(mod .. " + " .. "SHIFT" .. " + " .. "h", hl.dsp.window.resize({ x = -50, y = 0 }))

hl.bind(mod .. " + " .. "SHIFT" .. " + " .. "l", hl.dsp.window.resize({ x = 50, y = 0 }))

hl.bind(mod .. " + " .. "SHIFT" .. " + " .. "j", hl.dsp.window.resize({ x = 0, y = -50 }))

hl.bind(mod .. " + " .. "SHIFT" .. " + " .. "k", hl.dsp.window.resize({ x = 0, y = 50 }))

hl.bind(mod .. " + " .. "G", hl.dsp.group.toggle())

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "G", hl.dsp.window.move({ out_of_group = true }))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "N", hl.dsp.group.next())

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "P", hl.dsp.group.prev())

hl.bind(mod .. " + " .. "bracketleft", hl.dsp.focus({ workspace = "m-1" }))

hl.bind(mod .. " + " .. "bracketright", hl.dsp.focus({ workspace = "m+1" }))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "bracketleft", hl.dsp.focus({ monitor = "l" }))

hl.bind(mod .. " + " .. "CTRL" .. " + " .. "bracketright", hl.dsp.focus({ monitor = "r" }))

hl.bind(god .. " + " .. "O", hl.dsp.exec_cmd("swap-audio-output"))

hl.bind(god .. " + " .. "P", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+"))

hl.bind(god .. " + " .. "N", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-"))

hl.bind(god .. " + " .. "R", hl.dsp.exec_cmd("hyprctl hyprsunset temperature -500"))

hl.bind(god .. " + " .. "D", hl.dsp.exec_cmd("hyprctl hyprsunset temperature 6500"))

hl.bind(god .. " + " .. "B", hl.dsp.exec_cmd("hyprctl hyprsunset temperature +500"))

-- workspace switching: SUPER+<n> focuses it, +SHIFT moves the active window
-- there, +CTRL moves it there silently. evdev puts the number row at
-- code:10..19 for keys 1,2,...,9,0 -- so `9 + i` maps i=1..9 onto their own key
-- and i=10 onto the 0 key, which is where workspace 10 naturally lands.
for i = 1, 10 do
	local ws = tostring(i)
	local code = "code:" .. tostring(9 + i)
	hl.bind(mod .. " + " .. code, hl.dsp.focus({ workspace = ws }))
	hl.bind(mod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = ws }))
	hl.bind(mod .. " + CTRL + " .. code, hl.dsp.window.move({ workspace = ws }, { follow = false }))
end

hl.bind(mod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.bind(mod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mod .. " + " .. "ALT" .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.config({
	cursor = {
		default_monitor = "DP-2",
		no_hardware_cursors = 2,
	},
})

hl.config({
	ecosystem = {
		no_donation_nag = true,
		no_update_news = true,
	},
})

hl.env("NIXOS_OZONE_WL", 1)

hl.env("NVD_BACKEND", "direct")

hl.env("_JAVA_AWT_WM_NONREPARENTING", 1)

hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", 1)

hl.env("QT_QPA_PLATFORM", "wayland;xcb")

hl.env("SDL_VIDEODRIVER", "wayland")

hl.env("CLUTTER_BACKEND", "wayland")

hl.env("GDK_BACKEND", "wayland,x11,*")

hl.env("LIBVA_DRIVER_NAME", "nvidia")

hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

hl.env("GBM_BACKEND", "nvidia-drm")

hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.env("WLR_NO_HARDWARE_CURSORS", 1)

hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia")

hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", 1)

hl.config({
	general = {
		snap = {
			enabled = true,
		},
		allow_tearing = true,
		border_size = 1,
		gaps_in = 0,
		gaps_out = 0,
		col = {
			active_border = NIX.colors.active_border,
		},
	},
})

hl.config({
	group = {
		groupbar = {
			col = {
				active = NIX.colors.group_active,
				inactive = NIX.colors.group_inactive,
			},
			render_titles = false,
		},
	},
})

hl.config({
	input = {
		follow_mouse = 2,
		kb_layout = "us",
		repeat_delay = 200,
		repeat_rate = 50,
	},
})

hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},
})

hl.monitor({
	output = ml,
	mode = "7680x2160@120.00",
	position = "0x0",
	scale = 1.5,
})

hl.monitor({
	output = mr,
	mode = "3840x2160@60.00",
	position = "5120x-559",
	scale = 1.5,
	transform = 3,
})

-- Browsers, file managers and Electron apps request maximize on startup, and
-- Hyprland honors that request, so they open filling the screen. Terminals do
-- not request it, which is why kitty was unaffected. Hyprland's own example
-- config suppresses this for all apps; this config never carried the rule.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
hl.window_rule({
	name = "suppress-maximize-events",
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})

hl.window_rule({
	name = "clipse",
	match = {
		class = "clipse",
	},
	center = true,
	float = true,
	size = { 622, 652 },
	stay_focused = true,
})

hl.window_rule({
	name = "nemo",
	match = {
		class = "nemo",
	},
	float = true,
})

hl.window_rule({
	name = "feh",
	match = {
		class = "feh",
	},
	float = true,
})

hl.window_rule({
	name = "gcr-prompter",
	match = {
		class = "gcr-prompter",
	},
	center = true,
	stay_focused = true,
})

hl.window_rule({
	name = "bitwarden",
	match = {
		class = "chrome-nngceckbapebfimnlniiiahkandclblb-.*",
	},
	center = true,
	float = true,
	stay_focused = true,
})

-- workspace -> monitor: 1-5 on the left monitor, 6-10 on the right.
--
-- NOTE: the last one must be "10", not "0". Hyprland parses a numeric workspace
-- selector as `std::max(std::stoi(in), 1)` (getWorkspaceIDNameFromString in
-- helpers/MiscFunctions.cpp), so "0" clamps to 1 -- i.e. a rule written for "0"
-- silently becomes a second rule for workspace 1. getWorkspaceRuleFor merges
-- every matching rule in order and last-write-wins, so it would override ws 1's
-- monitor and layout with mr's.
for _, ws in ipairs({ "1", "2", "3", "4", "5" }) do
	hl.workspace_rule({ workspace = ws, monitor = ml })
end
-- mr is physically rotated (1440x2560 logical), and dwindle picks a split
-- orientation per node from `w > h * dwindle:split_width_multiplier`. The full
-- screen is taller than wide so the first split stacks, but each half is then
-- 1440x1280 -- wider than tall -- so every split after the first goes
-- side-by-side. split_width_multiplier is a global, so raising it to fix mr
-- would also wreck ml (5120x1440, which wants side-by-side columns).
--
-- Instead, register a Lua layout that always stacks evenly and scope it to mr's
-- workspaces. ctx:row(i, n) returns the i-th of n full-width horizontal bands.
-- hl.layout.register namespaces the layout as "lua:<name>".
--
-- Tradeoff: a Lua layout has no split ratios, so SUPER+SHIFT+hjkl (resize) is a
-- no-op on these workspaces; the bands are always equal. Focus (SUPER+hjkl) and
-- reordering (SUPER+CTRL+hjkl) work -- the latter swaps adjacent windows in the
-- stack.
hl.layout.register("vstack", {
	recalculate = function(ctx)
		local n = #ctx.targets
		for i, target in ipairs(ctx.targets) do
			target:place(ctx:row(i, n))
		end
	end,
})

for _, ws in ipairs({ "6", "7", "8", "9", "10" }) do
	hl.workspace_rule({ workspace = ws, monitor = mr, layout = "lua:vstack" })
end

hl.config({
	xwayland = {
		enabled = true,
		force_zero_scaling = true,
	},
})
