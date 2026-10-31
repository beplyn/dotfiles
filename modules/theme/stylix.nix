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

  # Papirus folder colour per accent
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
    # all schemes are dark
    polarity = "dark";
    image = lib.mkIf (!headless) (import ./wallpaper.nix { inherit config pkgs; });
    base16Scheme = base16Schemes.${themeName};
    targets = lib.mkMerge
    [
      { grub.enable = true; }
      # only with a display
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
      name = "Maple Mono NF";
      package = pkgs.maple-mono.NF;
    };
    opacity.terminal = 0.80;
    # waybar, quickshell, walker
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

  # servers: terminal targets only
  home-manager.sharedModules = lib.optional headless
  {
    # no dconf service without a session; other targets (eog, text editor) still write to it
    dconf.enable = false;
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
