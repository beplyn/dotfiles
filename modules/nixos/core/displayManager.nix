{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  services.displayManager.ly = {
    enable = true;
    package = pkgs.ly;
    settings = {
      animation = "none";

      clock = "%c";
      box_style = 2;
      bigclock = "en";

      bg = 0;
      fg = 7;
      border_fg = 6;
      input_fg = 4;
      hide_borders = false;
      blank_box = false;
      clear_password = true;

      box_title = "⚞^. .^⚟";
    };
  };

  stylix.targets.console.enable = true;
  environment.systemPackages = [
    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtsvg
  ];
}
