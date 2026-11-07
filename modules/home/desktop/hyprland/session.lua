-- Monitors and input (outputs.nix, settings.nix); touchpad gestures.
local outputs = require("haku.data.outputs")
local t = require("haku.data.theme")

for _, m in ipairs(outputs.monitors) do
    hl.monitor(m)
end
-- anything else plugged in
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.config({
    input = {
        kb_layout = t.kb_layout,
        kb_variant = t.kb_variant,
        -- niri's focus-follows-mouse
        follow_mouse = 1,
    },
    cursor = {
        hide_on_key_press = true,
    },
})

-- three fingers up and down through workspaces, as niri stacks them
hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })

if outputs.primary then
    hl.on("hyprland.start", function()
        hl.dispatch(hl.dsp.focus({ monitor = outputs.primary }))
    end)
end
