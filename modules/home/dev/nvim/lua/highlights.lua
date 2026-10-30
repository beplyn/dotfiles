function()
  local hl = vim.api.nvim_set_hl

  -- 1. Comments: Use base0C (Frost Cyan in Nord / Teal in Catppuccin)
  -- Distinct from standard text (base05) and highly legible on dark backgrounds
  hl(0, "Comment", { fg = "@cyan@", italic = true })
  hl(0, "@comment", { fg = "@cyan@", italic = true })
  hl(0, "@comment.documentation", { fg = "@cyan@", italic = true })
  hl(0, "gitcommitComment", { fg = "@cyan@", italic = true })
  hl(0, "SpecialComment", { fg = "@blue@", italic = true })

  -- 2. Relative Line Numbers: Explicitly style all three gutter groups
  hl(0, "LineNr", { fg = "@subtext@" })
  hl(0, "LineNrAbove", { fg = "@subtext@" })
  hl(0, "LineNrBelow", { fg = "@subtext@" })

  -- 3. Active Line Number: Bright accent with bold styling
  hl(0, "CursorLineNr", { fg = "@purple@", bold = true })

  -- 4. CursorLine: Subtle contrast row
  hl(0, "CursorLine", { bg = "@mantle@" })

  -- 5. Native Cmdline Popup (wildoptions=pum) & Menus
  hl(0, "Pmenu", { bg = "@mantle@", fg = "@foreground@" })
  hl(0, "PmenuSel", { bg = "@purple@", fg = "@background@", bold = true })
  hl(0, "PmenuSbar", { bg = "@mantle@" })
  hl(0, "PmenuThumb", { bg = "@purple@" })
  hl(0, "WildMenu", { bg = "@purple@", fg = "@background@", bold = true })

  -- 6. Floating Windows
  hl(0, "NormalFloat", { bg = "@mantle@", fg = "@foreground@" })
  hl(0, "FloatBorder", { fg = "@blue@", bg = "@mantle@" })
end
