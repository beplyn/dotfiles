{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  options.gaming.enable = lib.mkEnableOption "Steam and game launchers";

  config = lib.mkIf config.gaming.enable
  {
    programs.steam =
    {
      enable = true;
      package = pkgs.millennium-steam;
    };

    # gamemoderun %command%
    programs.gamemode =
    {
      enable = true;
      settings.general =
      {
        renice = 10;
        softrealtime = "auto";
        ioprio = 0;
        inhibit_screensaver = 1;
      };
    };
    users.users.${username}.extraGroups = [ "gamemode" ];

    # lets gamescope renice itself
    programs.gamescope =
    {
      enable = true;
      capSysNice = true;
    };
  };
}
