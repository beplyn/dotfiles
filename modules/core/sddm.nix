{ pkgs, ... }:

{
  services.displayManager.sddm =
  {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha-mauve";
    package = pkgs.kdePackages.sddm;
  };


  environment.systemPackages = [
    (pkgs.catppuccin-sddm.override
    {
      flavor = "mocha";
      accent = "mauve";
      font = "Maple Mono";
      fontSize = "12";
      #background = "/./wp.png";
    })

    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtsvg
  ];
}
