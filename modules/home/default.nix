{ lib, headless, ... }:

{
  imports = [
    ./dev
    ./cli
    ../theme
  ]
  ++ lib.optionals (!headless) [
    ./desktop
    ./wm
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
