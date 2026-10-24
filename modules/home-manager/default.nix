{ lib, headless, ... }:

{
  imports = [
    ./dev/module.nix
    ./cli/module.nix
    ../theme
  ]
  ++ lib.optionals (!headless) [
    ./graphical/module.nix
    ./wm/module.nix
  ];

  # Stylix themes these unconditionally; keep only terminal targets on servers.
  stylix.targets = lib.mkIf headless {
    gtk.enable = false;
    qt.enable = false;
    kde.enable = false;
    gnome.enable = false;
    font-packages.enable = false;
    fontconfig.enable = false;
  };
}
