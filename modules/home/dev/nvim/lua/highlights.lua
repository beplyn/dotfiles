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

  -- 3. Active Line Number: Bright accent with bold styling
  hl(0, "CursorLineNr", { fg = "@purple@", bold = true })

  -- 4. CursorLine: no fill, so the terminal's opacity shows through
  hl(0, "CursorLine", {})

  -- popup menus
  hl(0, "Pmenu", { bg = "@mantle@", fg = "@foreground@" })
  hl(0, "PmenuSel", { bg = "@purple@", fg = "@background@", bold = true })
  hl(0, "PmenuSbar", { bg = "@mantle@" })
  hl(0, "PmenuThumb", { bg = "@purple@" })
  hl(0, "WildMenu", { bg = "@purple@", fg = "@background@", bold = true })

  -- 6. Floating Windows
  hl(0, "NormalFloat", { bg = "@mantle@", fg = "@foreground@" })
  hl(0, "FloatBorder", { fg = "@blue@", bg = "@mantle@" })
end
