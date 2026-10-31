{ pkgs, ... }:

{
  imports = [ ./hardware.nix ];

  networking.hostName = "beacon";
  docker.enable = true;
  encryption.enable = false;
  services.openssh.enable = true;

  # wake-on-lan (magic packet) on every wired NIC; also needs WoL enabled in the BIOS
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="${pkgs.ethtool}/bin/ethtool -s $name wol g"
  '';
  # stop NetworkManager resetting it on connect (64 = magic)
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = 64;

  system.stateVersion = "26.11";
}
