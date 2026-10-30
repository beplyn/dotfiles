{ pkgs, ... }:

# Maple Mono NF (the Stylix monospace) is installed by Stylix itself.
{
  fonts.packages = with pkgs;
  [
    jetbrains-mono
    nerd-fonts.jetbrains-mono

    # MS Office fonts and metric-compatible stand-ins
    corefonts
    vista-fonts
    liberation_ttf
    carlito
    caladea
  ];
}
