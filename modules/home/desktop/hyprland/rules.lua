-- Floats for dialogs and the hypr tools.

-- Steam's News and Friends List windows float by default
hl.window_rule({
    name = "steam-popups",
    match = { class = "^steam$", title = "^(News|Friends List)$" },
    float = true,
})

-- Steam toasts top right, unfocused, just under the 26px waybar
local t = require("haku.data.theme")
hl.window_rule({
    name = "steam-toasts",
    match = { class = "^steam$", title = "^notificationtoasts_\\d+_desktop$" },
    float = true,
    no_initial_focus = true,
    move = { "(monitor_w-window_w-10)", tostring(26 + t.gaps) },
})

hl.window_rule({
    name = "satty",
    match = { class = "^com\\.gabm\\.satty$" },
    float = true,
})

-- file pickers and the like, centred
hl.window_rule({
    name = "dialogs",
    match = { title = "^(Open File|Open Folder|Select a File|Save As|File Upload|Choose wallpaper).*$" },
    float = true,
    center = true,
})

-- hyprland-dialog's prompts (the quit confirm), centred at their own size
hl.window_rule({
    name = "hypr-dialogs",
    match = { class = "^hyprland-dialog$" },
    float = true,
    center = true,
})

-- the hypr tools, centred at a comfortable size
hl.window_rule({
    name = "hypr-tools",
    match = { class = "^(hyprpwcenter|hyprsysteminfo)$" },
    float = true,
    center = true,
    size = { "(monitor_w*0.45)", "(monitor_h*0.5)" },
})

-- picture-in-picture pinned to the bottom right
hl.window_rule({
    name = "pip",
    match = { title = "^([Pp]icture[- ]?[Ii]n[- ]?[Pp]icture).*$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = { "(monitor_w*0.25)", "(monitor_h*0.25)" },
    move = { "(monitor_w*0.73)", "(monitor_h*0.72)" },
})

-- the layout decides sizes, not apps asking to maximize
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- XWayland drag-and-drop helpers, from Hyprland's default config
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})
