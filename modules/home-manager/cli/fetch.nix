{ config, lib, ... }:

let
  stylixBlue = config.lib.stylix.colors.base0D;
  stylixBlueRgb = lib.concatStringsSep ";" (
    builtins.map (part: toString (lib.fromHexString part)) [
      (builtins.substring 0 2 stylixBlue)
      (builtins.substring 2 2 stylixBlue)
      (builtins.substring 4 2 stylixBlue)
    ]
  );
in
{
  programs.fetch = {
    enable = true;
    info = [
      "host"
      "cpu"
      "gpu"
      "disk"
      "memory"
      "shell"
      "terminal"
      "font"
      "display"
      "wm"
      "os"
      "kernel"
      "packages"
      "uptime"
    ];
    labelColor = "white";
    extraConfig = "label_color=38;2;${stylixBlueRgb}";
    separator = " ";
    height = 20;
  };
}
