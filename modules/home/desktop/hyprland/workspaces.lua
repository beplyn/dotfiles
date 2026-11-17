-- hyprsplit: nine workspaces per monitor, shown as 1-9 on each
-- (1-9, 10-18, ... left to right, see outputs.nix)
local hs = require("hyprsplit")
local outputs = require("haku.data.outputs")

local count = 9
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
