-- merged over the stylix settings (color_scheme, font, window_background_opacity);
-- `wezterm` and `config` come from the Home Manager wrapper

config.default_cursor_style = "SteadyUnderline"
config.window_decorations = "NONE"
config.enable_tab_bar = false
config.window_padding =
{
  left = "14pt",
  right = "14pt",
  top = "14pt",
  bottom = "14pt",
}

config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"

-- copy on select, to the clipboard as well as primary
config.mouse_bindings =
{
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor "ClipboardAndPrimarySelection",
  },
}
