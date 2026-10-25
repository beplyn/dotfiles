{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "shulker";
  encryption.enable = false;
  services.openssh.enable = true;

  system.stateVersion = "26.11";
}
