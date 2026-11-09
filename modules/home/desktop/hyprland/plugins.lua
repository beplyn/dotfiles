-- The plugins plugins.nix loads, in Stylix's colours: hyprtasking's
-- overview (Mod+Tab), hyprfocus's flash on focus and borders-plus-plus's
-- outline; the hyprcursor theme too.
local p = require("haku.data.plugins")
local t = require("haku.data.theme")

-- "1d2021" -> "rgb(1d2021)" for Hyprland's colours, 0xAARRGGBB for plugins'
local function rgb(hex)
    return "rgb(" .. hex .. ")"
end
local function argb(hex, alpha)
    return tonumber(string.format("%02x", alpha or 255) .. hex, 16)
end

hl.config({
    plugin = {
        -- a grid of each monitor's workspaces; the borders are Stylix's
        -- col.active_border and col.inactive_border
        -- off with hyprtasking (plugins.nix)
        --[[
        hyprtasking = {
            layout = "grid",
            gap_size = t.gaps,
            bg_color = argb(p.colors.base00),
            border_size = t.border,
            exit_on_hovered = false,
            close_overview_on_reload = true,
            -- the keys on each workspace jump to it
            jump = {
                enabled = true,
                label_color = argb(p.colors.base05),
                label_background = argb(p.colors.base01, 0xcc),
                label_size = 32,
            },
            gestures = {
                enabled = false,
            },
            grid = {
                rows = 3,
                cols = 3,
                loop = false,
                gaps_use_aspect_ratio = true,
            },
        },
        ]]

        hyprfocus = {
            keyboard_focus_animation = "flash",
            mouse_focus_animation = "none",
            fade_opacity = 0.85,
        },

        -- a dark ring outside the border, to lift windows off the wallpaper
        borders_plus_plus = {
            add_borders = 1,
            natural_rounding = true,
            border_size_1 = 2,
            col = {
                border_1 = rgb(p.colors.base00),
            },
        },
    },
})

hl.animation({ leaf = "hyprfocusIn", enabled = true, speed = 1.7, bezier = "standard" })
hl.animation({ leaf = "hyprfocusOut", enabled = true, speed = 1.7, bezier = "standard" })

if p.cursor.theme then
    hl.env("HYPRCURSOR_THEME", p.cursor.theme)
    hl.env("HYPRCURSOR_SIZE", p.cursor.size)
end
