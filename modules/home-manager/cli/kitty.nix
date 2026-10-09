{ ... }:

{
  stylix.targets.kitty.enable = true;

  programs.kitty = {
    enable = true;

    settings = {
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
