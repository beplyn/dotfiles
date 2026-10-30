{
  config,
  lib,
  pkgs,
  ...
}:

let
  t = config.themes.shell;
  c = config.lib.stylix.colors.withHashtag;

  # screenshot [area|output]: save, copy, notify with edit/open actions
  screenshot = pkgs.writeShellApplication
  {
    name = "screenshot";
    runtimeInputs = with pkgs;
    [
      grim
      slurp
      wl-clipboard
      libnotify
      satty
      xdg-utils
      jq
    ];
    text = lib.replaceStrings
      [ "@base00@" "@base0E@" ]
      [ c.base00 c.base0E ]
      (builtins.readFile ./screenshot.sh);
  };
in
{
  home.packages = [ screenshot ];

  xdg.configFile."satty/config.toml".source = (pkgs.formats.toml { }).generate "satty-config"
  {
    general =
    {
      early-exit = true;
      initial-tool = "arrow";
      copy-command = "wl-copy";
      annotation-size-factor = 1.5;
      save-after-copy = true;
      default-hide-toolbars = false;
      corner-roundness = t.radius;
      actions-on-enter = [ "save-to-clipboard" ];
      actions-on-escape = [ "exit" ];
    };
    font.family = config.stylix.fonts.monospace.name;
    color-palette.palette =
    [
      c.base0E
      c.base08
      c.base09
      c.base0A
      c.base0B
      c.base0D
      c.base05
    ];
  };
}
