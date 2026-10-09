{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (lib.toLower config.networking.hostName != "larptop") {
    programs.steam = {
      enable = true;
      package = pkgs.millennium-steam;
    };
  };
}
