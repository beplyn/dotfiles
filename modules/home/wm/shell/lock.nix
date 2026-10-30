{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

# hyprlock over the Stylix wallpaper; colours from the palette.
let
  p = config.themes.palette;
  rgb = color: "rgb(${lib.removePrefix "#" color})";
  font = config.stylix.fonts.monospace.name;
  hyprlock = lib.getExe config.programs.hyprlock.package;
  pidof = lib.getExe' pkgs.procps "pidof";
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  niri = lib.getExe osConfig.programs.niri.package;
  # the stock blue snowflake; the ring around it carries the accent
  avatar = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake.png";
in
{
  programs.hyprlock =
  {
    enable = true;
    settings =
    {
      general =
      {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      animations.enabled = true;

      label =
      [
        {
          text = "$TIME";
          color = rgb p.foreground;
          font_size = 96;
          font_family = "${font} Bold";
          position = "0, 260";
          halign = "center";
          valign = "center";
        }
        {
          text = ''cmd[update:60000] date +"%A, %d %B"'';
          color = rgb p.subtext;
          font_size = 20;
          font_family = font;
          position = "0, 170";
          halign = "center";
          valign = "center";
        }
        {
          text = "Welcome back, $USER";
          color = rgb p.foreground;
          font_size = 16;
          font_family = font;
          position = "0, -95";
          halign = "center";
          valign = "center";
        }
      ];

      image =
      [
        {
          path = avatar;
          size = 120;
          rounding = -1;
          border_size = 3;
          border_color = rgb p.accent;
          position = "0, 10";
          halign = "center";
          valign = "center";
        }
      ];

      # attrset so it merges with Stylix
      input-field =
      {
        size = "340, 56";
        outline_thickness = 2;
        rounding = 14;
        dots_size = 0.22;
        dots_spacing = 0.4;
        dots_center = true;
        fade_on_empty = false;
        placeholder_text = "<i>Password</i>";
        fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
        font_family = font;
        position = "0, -175";
        halign = "center";
        valign = "center";
      };
    };
  };

  # inhibit_sleep: lock is up before suspend
  services.hypridle =
  {
    enable = true;
    settings =
    {
      general =
      {
        lock_cmd = "${pidof} hyprlock || ${hyprlock}";
        before_sleep_cmd = "${loginctl} lock-session";
        after_sleep_cmd = "${niri} msg action power-on-monitors";
        inhibit_sleep = 3;
      };
      listener =
      [
        {
          timeout = 300;
          on-timeout = "${loginctl} lock-session";
        }
        {
          timeout = 600;
          on-timeout = "${niri} msg action power-off-monitors";
          on-resume = "${niri} msg action power-on-monitors";
        }
      ];
    };
  };
}
