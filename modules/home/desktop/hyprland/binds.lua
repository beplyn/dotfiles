-- Binds from binds.nix: each names an hl.dsp dispatcher by its path, or one
-- of the functions below, with the argument it takes.
local binds = require("haku.data.binds")

local haku = {}

local dispatcher

local function scrolling()
    return hl.get_config("general.layout") == "scrolling"
end

-- Mod+Tab, for niri's overview: the scrolling layout zoomed out to every
-- column, then back to the focused one; nothing to zoom in tiling
local overview = false
function haku.overview()
    return function()
        if not scrolling() then
            overview = false
            return
        end
        overview = not overview
        hl.dispatch(hl.dsp.layout(overview and "fit all" or "fit active"))
    end
end

-- a scrolling layout message, which dwindle rejects with an error; there
-- the tiling { dsp, arg } instead, if any
function haku.scrolling(b)
    local tiling = b.tiling and dispatcher(b.tiling.dsp, b.tiling.arg)
    return function()
        if scrolling() then
            hl.dispatch(hl.dsp.layout(b.msg))
        elseif tiling then
            hl.dispatch(tiling)
        end
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

-- the windows of w's column, top to bottom; just w outside scrolling
local function column(w)
    local l = w.layout
    if scrolling() and type(l) == "table" and l.column then
        return l.column.windows
    end
    return { w }
end

local function address(w)
    return w and w.address
end

-- niri's focus-window-or-workspace: up and down the column, then on past
-- its end to the workspace above or below
function haku.focus_or_workspace(direction)
    local workspace = direction == "down" and "r+1" or "r-1"
    return function()
        local before = address(hl.get_active_window())
        hl.dispatch(hl.dsp.focus({ direction = direction }))
        if address(hl.get_active_window()) == before then
            hl.dispatch(hl.dsp.focus({ workspace = workspace }))
        end
    end
end

-- niri's move-column-left/right: swap the whole column with its neighbour;
-- the window alone in tiling
function haku.move_column(direction)
    return function()
        if scrolling() then
            hl.dispatch(hl.dsp.layout("swapcol " .. direction:sub(1, 1)))
        else
            hl.dispatch(hl.dsp.window.move({ direction = direction }))
        end
    end
end

-- niri's move-column-to-workspace: the focused window's whole column, still
-- stacked, to { workspace = n } or { offset = ±1 }; focus follows it
function haku.move_column_to_workspace(target)
    return function()
        local focused = hl.get_active_window()
        if not focused then
            return
        end
        local workspace = target.workspace or (focused.workspace.id + target.offset)
        if workspace < 1 or workspace == focused.workspace.id then
            return
        end
        local windows = column(focused)
        for _, w in ipairs(windows) do
            hl.dispatch(hl.dsp.window.move({
                workspace = workspace,
                follow = false,
                window = "address:" .. w.address,
            }))
        end
        hl.dispatch(hl.dsp.focus({ workspace = workspace }))
        -- they land as columns of their own, in order: stack each onto the
        -- one before
        for i = 2, #windows do
            hl.dispatch(hl.dsp.focus({ window = "address:" .. windows[i].address }))
            hl.dispatch(hl.dsp.layout("consume_or_expel prev"))
        end
        hl.dispatch(hl.dsp.focus({ window = "address:" .. focused.address }))
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

function dispatcher(path, arg)
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

return haku
