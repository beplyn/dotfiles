{
  config,
  lib,
  pkgs,
  ...
}:

# OpenRGB server, every LED in the Stylix accent. The GUI connects to the
# server and is a plain Qt app, so Stylix's qtct + Kvantum theme it
let
  cfg = config.services.hardware.openrgb;
  accent = lib.removePrefix "#" config.themes.palette.accent;

  openrgb-stylix = pkgs.writeShellApplication
  {
    name = "openrgb-stylix";
    runtimeInputs = [ cfg.package pkgs.coreutils pkgs.gnugrep ];
    text = builtins.readFile ./openrgb-stylix.sh;
  };
in
{
  options.rgb.enable = lib.mkEnableOption "OpenRGB with the LEDs in Stylix colours";

  config = lib.mkIf config.rgb.enable
  {
    services.hardware.openrgb =
    {
      enable = true;
      motherboard = lib.mkDefault "amd";
    };

    # the CLI only talks to the local server, which the GUI uses as well
    environment.systemPackages = [ openrgb-stylix ];

    # once the server has detected everything; the scheme changes on rebuild
    systemd.services.openrgb-stylix =
    {
      description = "Paint the RGB LEDs in the Stylix accent";
      wantedBy = [ "openrgb.service" ];
      after = [ "openrgb.service" ];
      bindsTo = [ "openrgb.service" ];
      restartTriggers = [ accent ];
      serviceConfig =
      {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe openrgb-stylix} ${accent}";
        DynamicUser = true;
        # OpenRGB keeps a config dir in $HOME
        StateDirectory = "openrgb-stylix";
        Environment = "HOME=%S/openrgb-stylix";
      };
    };

    # the GUI in the tray at login, a client of the server with the Stylix
    # profile the oneshot above saved
    systemd.user.services.openrgb-gui =
    {
      description = "OpenRGB GUI in the tray";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig =
      {
        ExecStart = "${lib.getExe cfg.package} --startminimized --profile stylix";
        Restart = "on-failure";
      };
    };

    # some controllers forget their colours over suspend
    powerManagement.resumeCommands = "${config.systemd.package}/bin/systemctl restart --no-block openrgb-stylix.service";
  };
}
