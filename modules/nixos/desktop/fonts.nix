{
  config,
  lib,
  pkgs,
  ...
}:

# Maple Mono NF (the Stylix monospace) is installed by Stylix itself.
{
  fonts.packages = with pkgs;
  [
    jetbrains-mono
    nerd-fonts.jetbrains-mono

    # metric-compatible stand-ins for the MS Office fonts
    liberation_ttf
    carlito
    caladea
    dejavu_fonts
    noto-fonts
    noto-fonts-color-emoji
  ]
  # the MS Office fonts themselves are unfree
  ++ lib.optionals config.unfree.enable
  [
    corefonts
    vista-fonts
  ];
}
