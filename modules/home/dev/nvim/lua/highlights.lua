function()
  local hl = vim.api.nvim_set_hl

  -- 1. Comments: Use base0C (Frost Cyan in Nord / Teal in Catppuccin)
  -- Distinct from standard text (base05) and highly legible on dark backgrounds
  hl(0, "Comment", { fg = "@base0C@", italic = true })
  hl(0, "@comment", { fg = "@base0C@", italic = true })
  hl(0, "@comment.documentation", { fg = "@base0C@", italic = true })
  hl(0, "gitcommitComment", { fg = "@base0C@", italic = true })
  hl(0, "SpecialComment", { fg = "@base0D@", italic = true })

  -- 2. Relative Line Numbers: Explicitly style all three gutter groups
  hl(0, "LineNr", { fg = "@base04@" })
  hl(0, "LineNrAbove", { fg = "@base04@" })
  hl(0, "LineNrBelow", { fg = "@base04@" })

  -- 3. Active Line Number: Bright accent with bold styling
  hl(0, "CursorLineNr", { fg = "@base0E@", bold = true })

  -- 4. CursorLine: Subtle contrast row
  hl(0, "CursorLine", { bg = "@base01@" })

  -- 5. Native Cmdline Popup (wildoptions=pum) & Menus
  hl(0, "Pmenu", { bg = "@base01@", fg = "@base05@" })
  hl(0, "PmenuSel", { bg = "@base0E@", fg = "@base00@", bold = true })
  hl(0, "PmenuSbar", { bg = "@base01@" })
  hl(0, "PmenuThumb", { bg = "@base0E@" })
  hl(0, "WildMenu", { bg = "@base0E@", fg = "@base00@", bold = true })

  -- 6. Floating Windows
  hl(0, "NormalFloat", { bg = "@base01@", fg = "@base05@" })
  hl(0, "FloatBorder", { fg = "@base0D@", bg = "@base01@" })
end
