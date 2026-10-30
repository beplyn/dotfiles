-- inlined into init.lua: a top-level `return` here would skip the rest of the config
local ok, alpha = pcall(require, "alpha")
if ok and vim.fn.argc() == 0 then
  local dashboard = require("alpha.themes.dashboard")
  local random_logo = require("random_logo")

  local function button(sc, txt, keybind)
    local b = dashboard.button(sc, txt, keybind)
    b.opts.hl = "DashboardCenter"
    b.opts.hl_shortcut = "DashboardShortcut"
    return b
  end

  dashboard.section.buttons.val = {
    button("n", "  New file", "<cmd>ene <BAR> startinsert<CR>"),
    button("f", "󰈞  Find file", "<cmd>Telescope find_files<CR>"),
    button("r", "󰄉  Recent files", "<cmd>Telescope oldfiles<CR>"),
    button("g", "󰊄  Live grep", "<cmd>Telescope live_grep<CR>"),
    button("c", "  Config", "<cmd>cd /etc/nixos <BAR> e flake.nix<CR>"),
    button("q", "󰩈  Quit", "<cmd>qa<CR>"),
  }

  local chosen_color_hex = random_logo.get_accent_color()
  vim.api.nvim_set_hl(0, "DashboardRandomLogo", { fg = chosen_color_hex, bold = true })
  vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "@cyan@" })
  vim.api.nvim_set_hl(0, "DashboardCenter", { fg = "@subtext@" })
  vim.api.nvim_set_hl(0, "DashboardShortcut", { fg = "@purple@" })

  dashboard.section.header.val = random_logo.get_header()
  dashboard.section.header.opts.hl = "DashboardRandomLogo"

  alpha.setup(dashboard.opts)
end
