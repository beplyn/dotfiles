-- merged over the stylix settings (color_scheme, font, window_background_opacity);
-- `wezterm` and `config` come from the Home Manager wrapper

-- no trail shaders in wezterm; the closest it gets is an eased blink
config.default_cursor_style = "BlinkingUnderline"
config.cursor_blink_rate = 600
config.cursor_blink_ease_in = "EaseOut"
config.cursor_blink_ease_out = "EaseOut"
-- the default 10 fps makes the fade step visibly
config.animation_fps = 120

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
-- the sudo prompt brings its own lock glyph
config.detect_password_input = false

-- copy on select, to the clipboard as well as primary
config.mouse_bindings =
{
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor "ClipboardAndPrimarySelection",
  },
}
