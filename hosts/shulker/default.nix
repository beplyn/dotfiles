{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "shulker";
  encryption.enable = false;

  system.stateVersion = "26.11";
}
