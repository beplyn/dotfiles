local dashboard = require("alpha.themes.dashboard")
local random_logo = require("random_logo")

local chosen_color_hex = random_logo.get_accent_color()
vim.api.nvim_set_hl(0, "DashboardRandomLogo", { fg = chosen_color_hex, bold = true })

dashboard.section.header.val = random_logo.get_header()
dashboard.section.header.opts.hl = "DashboardRandomLogo"
