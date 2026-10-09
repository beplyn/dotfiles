local M = {}

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
  local accents = {
    vim.api.nvim_get_hl(0, { name = "DiagnosticError", link = false }).fg,
    vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false }).fg,
    vim.api.nvim_get_hl(0, { name = "DiagnosticInfo", link = false }).fg,
    vim.api.nvim_get_hl(0, { name = "DiagnosticHint", link = false }).fg,
    vim.api.nvim_get_hl(0, { name = "Directory", link = false }).fg,
  }
  local available = vim.tbl_filter(function(color)
    return color ~= nil
  end, accents)

  return string.format("#%06x", available[math.random(#available)])
end

return M
