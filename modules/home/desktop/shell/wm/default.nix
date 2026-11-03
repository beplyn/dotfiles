{
  lib,
  osConfig,
  pkgs,
  ...
}:

# wm: the running compositor's name, focused output and monitor power, for
# scripts and services
let
  wm = pkgs.writeShellApplication
  {
    name = "wm";
    runtimeInputs = with pkgs;
    [
      gnugrep
      jq
      slurp
      wlr-randr
      wlopm
      wayland-utils
      osConfig.programs.niri.package
      osConfig.programs.sway.package
    ];
    text = builtins.readFile ./wm.sh;
  };
in
{
  home.packages = [ wm ];

  lib.haku.wm = wm;
}
