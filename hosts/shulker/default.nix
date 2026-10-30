{
  imports =
  [
    ./hardware.nix
  ];

  networking.hostName = "shulker";
  docker.enable = true;
  qbittorrent.enable = true;
  encryption.enable = false;
  services.openssh.enable = true;
  # No monitors: niri follows the VM window and guest agent resizes.

  system.stateVersion = "26.11";
}
