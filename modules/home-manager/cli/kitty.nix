{
  config,
  lib,
  pkgs,
  ...
}:

{
  stylix.targets.kitty.enable = true;

  programs.kitty = {
    enable = true;
    enableGitIntegration = true;
    shellIntegration.enableFishIntegration = true;

    font = {
      name = lib.mkForce "Maple Mono NF";
      package = lib.mkForce pkgs.maple-mono.NF;
      size = 12;
    };

    settings = {
      bold_font = "auto";

      # Follow Stylix's base00 so the background matches every theme. Blur is
      # done by niri's window rule (see wm/niri/kdl.nix), so no
      # background_blur here.
      background = lib.mkForce "#${config.lib.stylix.colors.base00}";
      background_opacity = lib.mkForce "0.80";
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
