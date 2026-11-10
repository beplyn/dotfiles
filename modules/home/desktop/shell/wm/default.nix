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
    ];
    text = builtins.readFile ./wm.sh;
  };

  # started by sessions whose exit leaves graphical-session.target up
  session-watch = pkgs.writeShellApplication
  {
    name = "session-watch";
    runtimeInputs = with pkgs;
    [
      bash
      coreutils
      gnugrep
      iproute2
      systemd
    ];
    text = builtins.readFile ./session-watch.sh;
  };
in
{
  home.packages = [ wm ];

  lib.haku.wm = wm;
  lib.haku.sessionWatch = session-watch;
}
