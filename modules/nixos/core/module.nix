{
  lib,
  pkgs,
  themeName,
  headless,
  ...
}:

let
  base16Schemes = {
    catppuccin = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    gruvbox = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    nord = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  };
in
{
  imports = [
    ./boot.nix
    ./containers.nix
    ./qbit.nix
    ./networking.nix
    ./ssh.nix
    ./locale.nix
    ./encryption.nix
  ]
  ++ lib.optionals (!headless) [
    ./audio.nix
    ./desktop.nix
    ./displayManager.nix
    ./kdeconnect.nix
  ];

  stylix = {
    enable = true;
    base16Scheme = base16Schemes.${themeName};
    targets = lib.mkMerge [
      { grub.enable = true; }
      # Desktop theming only matters with a display.
      (lib.mkIf headless {
        gtk.enable = false;
        qt.enable = false;
        gnome.enable = false;
        font-packages.enable = false;
        fontconfig.enable = false;
      })
    ];
    fonts.monospace = {
      name = "Maple Mono";
      package = pkgs.maple-mono.truetype;
    };
    opacity.terminal = 0.75;
    # Shell surfaces: waybar, quickshell panels, walker.
    opacity.desktop = 0.82;
    cursor = lib.mkIf (!headless) {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };
}
