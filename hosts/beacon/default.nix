{ pkgs, ... }:

{
  imports = [ ./hardware.nix ];

  networking.hostName = "beacon";
  docker.enable = true;
  encryption.enable = false;
  services.openssh.enable = true;

  environment.systemPackages = [ pkgs.kitty.terminfo ];

  # wake-on-lan (magic packet) on every wired NIC; also needs WoL enabled in the BIOS
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="${pkgs.ethtool}/bin/ethtool -s $name wol g"
  '';
  # stop NetworkManager resetting it on connect (64 = magic)
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = 64;

  # static ip; no interface-name so it binds to whichever wired NIC is present
  networking.networkmanager.ensureProfiles.profiles.wired = {
    connection = {
      id = "wired";
      type = "ethernet";
      autoconnect-priority = 100;
    };
    ipv4 = {
      method = "manual";
      address1 = "192.168.2.200/24,192.168.2.1";
      dns = "192.168.2.1;";
    };
    ipv6.method = "auto";
  };

  system.stateVersion = "26.11";
}
