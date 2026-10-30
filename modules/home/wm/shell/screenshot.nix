{
  config,
  pkgs,
  subst,
  ...
}:

let
  t = config.themes.shell;
  p = config.themes.palette;

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
    text = subst { inherit (p) background accent; } (builtins.readFile ./screenshot.sh);
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
      p.accent
      p.red
      p.orange
      p.yellow
      p.green
      p.blue
      p.foreground
    ];
  };
}
