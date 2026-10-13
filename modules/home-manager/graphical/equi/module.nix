{
  ...
}:

{
  imports = [
    ./notifications.nix
    ./rpc.nix
    ./tray.nix
  ];

  programs.equibop = {
    enable = true;

    settings = {
      checkUpdates = false;
      discordBranch = "stable";
      spellCheckLanguages = [ "en" ];

      hardwareAcceleration = true;
      hardwareVideoAcceleration = true;
      webRTCIPHandlingPolicy = "disable_non_proxied_udp";
    };
  };
}
