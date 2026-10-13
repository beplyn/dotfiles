{ pkgs, themeName, ... }:

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
    ./qbit.nix
    ./networking.nix
    ./locale.nix
    ./displayManager.nix
    ./kdeconnect.nix
    ./niri.nix
  ];

  stylix = {
    enable = true;
    base16Scheme = base16Schemes.${themeName};
    targets.grub.enable = true;
    fonts.monospace.name = "Maple Mono";
    opacity.terminal = 0.65;
  };
}
