-- Binds from binds.nix: each names an hl.dsp dispatcher by its path, or one
-- of the functions below, with the argument it takes.
local binds = require("haku.data.binds")

local haku = {}

-- Mod+Tab, for niri's overview: the scrolling layout zoomed out to every
-- column, then back to the focused one
local overview = false
function haku.overview()
    return function()
        overview = not overview
        hl.dispatch(hl.dsp.layout(overview and "fit all" or "fit active"))
    end
end

-- the next of these layouts, for every workspace; a reload starts over at
-- look.lua's
function haku.cycle_layout(layouts)
    return function()
        local current = hl.get_config("general.layout")
        local next = layouts[1]
        for i, name in ipairs(layouts) do
            if name == current then
                next = layouts[i % #layouts + 1]
            end
        end
        hl.config({ general = { layout = next } })
    end
end

-- hyprsunset at this temperature, or back to none
local night = false
function haku.night_light(temperature)
    return function()
        night = not night
        hl.exec_cmd(night and ("hyprctl hyprsunset temperature " .. temperature) or "hyprctl hyprsunset identity")
    end
end

local function dispatcher(path, arg)
    local custom = path:match("^haku%.(.+)$")
    if custom then
        return haku[custom](arg)
    end
    local fn = hl.dsp
    for part in path:gmatch("[^.]+") do
        fn = fn[part]
    end
    return fn(arg)
end

for _, b in ipairs(binds) do
    hl.bind(b.key, dispatcher(b.dsp, b.arg), b.opts)
end

-- Mod+drag moves, Mod+right-drag resizes, as in niri
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Mod+scroll through workspaces, Mod+Shift+scroll through columns
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.layout("move +col"))
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.layout("move -col"))
