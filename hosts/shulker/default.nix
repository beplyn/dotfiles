{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "shulker";

  system.stateVersion = "26.11";
}
