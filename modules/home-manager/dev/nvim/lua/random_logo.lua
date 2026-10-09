local M = {}

local mocha_accents = {
  rosewater = "#f5e0dc",
  flamingo = "#f2cdcd",
  pink = "#f5c2e7",
  mauve = "#cba6f7",
  red = "#f38ba8",
  maroon = "#eba0ac",
  peach = "#fab387",
  yellow = "#f9e2af",
  green = "#a6e3a1",
  teal = "#94e2d5",
  sky = "#89dceb",
  sapphire = "#74c7ec",
  blue = "#89b4fa",
  lavender = "#b4befe",
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
  local accents = {}
  for _, color in pairs(mocha_accents) do
    table.insert(accents, color)
  end

  return accents[math.random(#accents)]
end

return M
