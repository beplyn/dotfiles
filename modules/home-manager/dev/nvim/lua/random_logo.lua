local M = {}

local theme_accents = {
  catppuccin = {
    "#f38ba8", -- red
    "#fab387", -- orange
    "#f9e2af", -- yellow
    "#a6e3a1", -- green
    "#94e2d5", -- aqua
    "#89b4fa", -- blue
    "#cba6f7", -- purple
  },
  gruvbox = {
    "#cc241d", -- red
    "#d65d0e", -- orange
    "#d79921", -- yellow
    "#98971a", -- green
    "#689d6a", -- aqua
    "#458588", -- blue
    "#b16286", -- purple
  },
  nord = {
    "#bf616a", -- red
    "#d08770", -- orange
    "#ebcb8b", -- yellow
    "#a3be8c", -- green
    "#8fbcbb", -- aqua
    "#81a1c1", -- blue
    "#b48ead", -- purple
  },
}

math.randomseed(os.time())

function M.get_header()
  local logo_pattern = vim.fn.stdpath("config") .. "/logos/*.ascii"
  local logos = vim.fn.glob(logo_pattern, false, true)

  if #logos == 0 then
    error("No ASCII logos found in " .. vim.fn.fnamemodify(logo_pattern, ":h"))
  end

  local logo = logos[math.random(#logos)]
  local lines = vim.fn.readfile(logo)

  if #lines == 0 then
    error("ASCII logo is empty: " .. logo)
  end

  return lines
end

function M.get_accent_color()
  local colorscheme = vim.g.colors_name or "catppuccin"
  local accents = theme_accents[colorscheme]

  if not accents then
    accents = theme_accents[colorscheme:match("^[^-]+")] or theme_accents.catppuccin
  end

  return accents[math.random(#accents)]
end

return M
