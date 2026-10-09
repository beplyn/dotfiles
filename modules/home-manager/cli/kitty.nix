{ config, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "Maple Mono";
      size = 13;
    };

    settings = {
      foreground = config.themes.palette.foreground;
      background = config.themes.palette.background;
      cursor = config.themes.palette.foreground;
      selection_background = config.themes.palette.surfaceBright;
      selection_foreground = "none";

      color0 = config.themes.palette.surface;
      color1 = config.themes.palette.red;
      color2 = config.themes.palette.green;
      color3 = config.themes.palette.yellow;
      color4 = config.themes.palette.blue;
      color5 = config.themes.palette.purple;
      color6 = config.themes.palette.aqua;
      color7 = config.themes.palette.foreground;
      color8 = config.themes.palette.surfaceBright;
      color9 = config.themes.palette.red;
      color10 = config.themes.palette.green;
      color11 = config.themes.palette.yellow;
      color12 = config.themes.palette.blue;
      color13 = config.themes.palette.purple;
      color14 = config.themes.palette.aqua;
      color15 = config.themes.palette.foreground;

      background_opacity = 0.65;
      background_blur = 20;

      cursor_shape = "underline";
      window_padding_width = 8;
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
