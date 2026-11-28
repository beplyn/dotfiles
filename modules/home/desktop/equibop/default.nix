{ inputs, ... }:
{
  imports =
  [
    inputs.nixcord.homeModules.nixcord
    ./notifications.nix
    ./rpc.nix
    ./tray.nix
    ./equicord
  ];

  programs.nixcord =
  {
    enable = true;
    # Equibop only; Discord itself isn't installed
    discord.enable = false;
    equibop.enable = true;
    equibop.settings =
    {
      checkUpdates = false;
      discordBranch = "stable";
      spellCheckLanguages = [ "en" ];

      hardwareAcceleration = true;
      hardwareVideoAcceleration = true;
      webRTCIPHandlingPolicy = "disable_non_proxied_udp";
    };
  };
}
