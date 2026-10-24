{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  swaylock = lib.getExe config.programs.swaylock.package;
  niri = lib.getExe osConfig.programs.niri.package;
  lock = "${swaylock} -f";
in
{
  # Colors come from stylix.targets.swaylock, so they follow the theme.
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      effect-blur = "7x5";
      effect-vignette = "0.4:0.6";
      fade-in = 0.2;

      clock = true;
      timestr = "%H:%M";
      datestr = "%A, %d %B";
      font = config.stylix.fonts.monospace.name;
      font-size = 28;

      indicator = true;
      indicator-radius = 120;
      indicator-thickness = 8;
      ignore-empty-password = true;
      show-failed-attempts = true;
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = lock;
      }
      {
        timeout = 600;
        command = "${niri} msg action power-off-monitors";
        resumeCommand = "${niri} msg action power-on-monitors";
      }
    ];
    events = {
      before-sleep = lock;
      inherit lock;
    };
  };
}
