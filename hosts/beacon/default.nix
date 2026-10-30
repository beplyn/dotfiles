{
  imports = [ ./hardware.nix ];

  networking.hostName = "beacon";
  docker.enable = true;
  encryption.enable = false;
  services.openssh.enable = true;

  system.stateVersion = "26.11";
}
