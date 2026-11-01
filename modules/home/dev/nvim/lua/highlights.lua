function()
  local hl = vim.api.nvim_set_hl

  -- comments
  hl(0, "Comment", { fg = "@cyan@", italic = true })
  hl(0, "@comment", { fg = "@cyan@", italic = true })
  hl(0, "@comment.documentation", { fg = "@cyan@", italic = true })
  hl(0, "gitcommitComment", { fg = "@cyan@", italic = true })
  hl(0, "SpecialComment", { fg = "@blue@", italic = true })

  -- line numbers
  hl(0, "LineNr", { fg = "@subtext@" })
  hl(0, "LineNrAbove", { fg = "@subtext@" })
  hl(0, "LineNrBelow", { fg = "@subtext@" })

  -- no cursorline fill: terminal opacity shows through
  hl(0, "CursorLine", {})

  -- popup menus
  hl(0, "Pmenu", { bg = "@mantle@", fg = "@foreground@" })
  hl(0, "PmenuSel", { bg = "@accent@", fg = "@background@", bold = true })
  hl(0, "PmenuSbar", { bg = "@mantle@" })
  hl(0, "PmenuThumb", { bg = "@accent@" })
  hl(0, "WildMenu", { bg = "@accent@", fg = "@background@", bold = true })

  -- floats: transparent, like the main window
  hl(0, "NormalFloat", { bg = "NONE", fg = "@foreground@" })
  hl(0, "FloatBorder", { bg = "NONE", fg = "@blue@" })
end
