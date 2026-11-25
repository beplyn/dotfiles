{ domain, ... }:

{
  imports = [ ./hardware.nix ./hardware-extra.nix ];

  networking.hostName = "shulker";
  # beacon's wg0 peer; it is reached at its DDNS name
  wireguard =
  {
    enable = true;
    address = "10.100.0.3/24";
    peers =
    [
      {
        # beacon's public key (its wg pubkey)
        publicKey = "";
        allowedIPs = [ "10.100.0.1/32" ];
        endpoint = "${domain}:51820";
        persistentKeepalive = 25;
      }
    ];
  };
  laptop.enable = true;
  toolbox.enable = true;
  services.xserver.xkb.layout = "us";
  console.keyMap = "us";
  monitors =
  [
    {
      name = "eDP-1";
      width = 1920;
      height = 1080;
      refresh = 60.0;
      primary = true;
    }
  ];
  encryption.device = "/dev/disk/by-uuid/b92ea2f5-494b-43e6-adcb-53b98d1b0847";

  system.stateVersion = "26.11";
}
