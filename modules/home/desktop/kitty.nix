{
  config,
  lib,
  ...
}:

# font and opacity come from Stylix (fonts.monospace, opacity.terminal)
{
  programs.kitty =
  {
    enable = true;
    enableGitIntegration = true;
    shellIntegration.enableFishIntegration = true;

    settings =
    {
      bold_font = "auto";

      # base00 background; blur comes from niri
      background = lib.mkForce config.themes.palette.background;
      dynamic_background_opacity = true;

      cursor_shape = "underline";
      window_padding_width = 14;
      hide_window_decorations = true;
      tab_bar_style = "hidden";

      scrollback_lines = 10000;
      url_style = "dotted";
      copy_on_select = true;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
    };
  };
}
