{ pkgs, ... }:

{
  services.displayManager.sddm =
  {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
  };


  environment.systemPackages = [
    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtsvg
  ];
}
