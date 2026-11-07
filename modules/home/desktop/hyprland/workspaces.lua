-- hyprsplit: ten workspaces per monitor, as niri keeps them per output.
-- Monitors take theirs left to right (outputs.nix), 1-10, 11-20, ...; each
-- is named 1-10 on its own monitor so waybar and the overview number them so.
local hs = require("hyprsplit")
local outputs = require("haku.data.outputs")

local count = 10
hs.config({ num_workspaces = count })

local names = {}
for i, m in ipairs(outputs.monitors) do
    names[i] = m.output
    for n = 1, count do
        hl.workspace_rule({
            workspace = tostring((i - 1) * count + n),
            monitor = m.output,
            default_name = tostring(n),
        })
    end
end
if #names > 0 then
    hs.monitor_priority(names)
end
