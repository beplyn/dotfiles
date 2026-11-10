-- Layout, decoration and motion. Gaps, borders and columns from the shell
-- theme (settings.nix); the curves are Material 3 motion, as in caelestia's and
-- end-4's rices. Stylix sets the colours in hyprland.lua.
local t = require("haku.data.theme")

hl.config({
    general = {
        -- tiling; niri's columns (scrolling) on Mod+T
        layout = "dwindle",
        gaps_in = t.gaps,
        gaps_out = t.gaps,
        gaps_workspaces = 50,
        border_size = t.border,
        resize_on_border = true,
        -- focus stops at a column's ends, as in niri, rather than wrapping;
        -- Mod+J/K then carry on to the next workspace (binds.lua)
        no_focus_fallback = true,
        snap = {
            enabled = true,
            window_gap = t.gaps,
            monitor_gap = t.gaps,
            respect_gaps = true,
        },
    },

    -- the scrolling layout on Mod+T
    scrolling = {
        column_width = t.column_width,
        explicit_column_widths = t.column_widths,
        -- center-focused-column "never": scroll just far enough
        focus_fit_method = 1,
        follow_focus = true,
    },

    -- the tiling layout on Mod+T
    dwindle = {
        preserve_split = true,
        smart_resizing = true,
    },

    decoration = {
        rounding = t.radius,
        -- squircle corners
        rounding_power = 2.5,
        -- frosted glass behind the translucent shell and windows
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            noise = 0.02,
            vibrancy = 0.2,
            new_optimizations = true,
            popups = true,
        },
        -- niri's: soft, 4px down
        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            offset = { 0, 4 },
        },
        -- the scratchpad dims what is under it
        dim_special = 0.3,
    },

    animations = {
        enabled = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        focus_on_activate = true,
        animate_manual_resizes = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },

    -- XWayland apps unscaled rather than blurry
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("menuDecel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
-- a slight overshoot for moving windows
hl.curve("expressiveSpatial", { type = "bezier", points = { { 0.38, 1.21 }, { 0.22, 1 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "emphasizedDecel", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "emphasizedAccel", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "expressiveSpatial", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "standard" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "menuDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "menuDecel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2, bezier = "emphasizedAccel" })
-- niri's workspaces stack vertically
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "emphasizedDecel", style = "slidefadevert 15%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "standard" })

-- frosted shell: the bar and quickshell's panels blur what is
-- behind them; ignore_alpha keeps their clear margins sharp
hl.layer_rule({
    name = "frosted-shell",
    match = { namespace = "^(waybar|haku-.*)$" },
    blur = true,
    ignore_alpha = 0.3,
})

-- pickers and region selection appear at once
hl.layer_rule({
    name = "instant-pickers",
    match = { namespace = "^(hyprpicker|selection)$" },
    no_anim = true,
})
