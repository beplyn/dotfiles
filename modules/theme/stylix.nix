{
  config,
  lib,
  pkgs,
  themeName,
  headless,
  ...
}:

let
  base16Schemes =
  {
    catppuccin = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    gruvbox = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    nord = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  };

  # Papirus folder colour closest to each scheme's base0E accent.
  folderColors =
  {
    catppuccin = "violet";
    gruvbox = "pink";
    nord = "nordic";
  };
in
{
  stylix =
  {
    enable = true;
    # All shipped schemes are dark; GTK/libadwaita and the greeter read this.
    polarity = "dark";
    image = lib.mkIf (!headless) (import ./wallpaper.nix { inherit config pkgs; });
    base16Scheme = base16Schemes.${themeName};
    targets = lib.mkMerge
    [
      { grub.enable = true; }
      # Desktop theming only matters with a display.
      (lib.mkIf headless
      {
        gtk.enable = false;
        qt.enable = false;
        gnome.enable = false;
        font-packages.enable = false;
        fontconfig.enable = false;
      })
    ];
    fonts.monospace =
    {
      name = "Maple Mono";
      package = pkgs.maple-mono.truetype;
    };
    opacity.terminal = 0.75;
    # Shell surfaces: waybar, quickshell panels, walker.
    opacity.desktop = 0.82;
    cursor = lib.mkIf (!headless)
    {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
    icons = lib.mkIf (!headless)
    {
      enable = true;
      package = pkgs.papirus-icon-theme.override { color = folderColors.${themeName}; };
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };
  };

  # Stylix themes these unconditionally in Home Manager; keep only terminal
  # targets on servers.
  home-manager.sharedModules = lib.optional headless
  {
    stylix.targets =
    {
      gtk.enable = false;
      qt.enable = false;
      kde.enable = false;
      gnome.enable = false;
      font-packages.enable = false;
      fontconfig.enable = false;
    };
  };
}
