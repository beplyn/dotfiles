{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (lib.toLower config.networking.hostName == "anvil") {
    programs.steam = {
      enable = true;
      package = pkgs.millennium-steam;
    };
  };
}
