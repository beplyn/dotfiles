{
  config,
  lib,
  pkgs,
  ...
}:

# Serein reads themes only from imported .serein-extension files (Settings > Themes > Import),
# so the Stylix palette is written as one here. Re-import it after the palette changes.
let
  c = config.lib.stylix.colors.withHashtag;
  p = config.themes.palette;
  shell = config.themes.shell;
  round = x: builtins.floor (x + 0.5);
  clamp = x: lo: hi: if x < lo then lo else if x > hi then hi else x;

  colors =
  {
    base = c.base00;
    sidebar = c.base01;
    chat = c.base00;
    raised = c.base01;
    hover = c.base02;
    selected = c.base02;
    border = c.base03;
    text_strong = c.base07;
    text = c.base05;
    muted = c.base04;
    link = p.cyan;
    accent = p.accent;
    accent_text = c.base00;
    positive = p.success;
    warning = p.warning;
    danger = p.error;
    mention_bg = p.purple;
    mention_text = c.base00;
  };

  # shell font sizes are points, Serein's are pixels; radii carry over as they are
  style =
  {
    body_size = clamp (round (shell.popupFontSize * 4 / 3)) 10 28;
    widget_radius = clamp shell.radius 0 24;
    window_radius = clamp shell.radius 0 24;
    menu_radius = clamp shell.radius 0 24;
  };

  # one Stylix scheme drives both appearances, so both get the same colours
  themeFile = pkgs.writeText "stylix.serein-extension" (builtins.toJSON
  {
    manifest =
    {
      api_version = 1;
      id = "stylix";
      name = "Stylix";
      version = "1.0.0";
      author = "generated from Stylix";
      license = "MIT";
      source = "https://github.com/nix-community/stylix";
      kind = "theme";
    };
    theme =
    {
      dark.colors = colors;
      light.colors = colors;
      inherit style;
    };
  });
in
{
  home.packages =
  [
    # native Discord client in Rust, via lib/mkHost.nix's overlay
    pkgs.serein
  ];

  home.file.".local/share/serein-themes/stylix.serein-extension".source = themeFile;
}
