{ lib, pkgs, domain, lan, ... }:

# its address, gateway and subnet are vars (vars/README.md), not in the repo
let
  inherit (lan) address subnet gateway;
  prefix = lib.last (lib.splitString "/" subnet);
in
{
  assertions =
  [
    {
      assertion = address != "" && gateway != "" && lib.hasInfix "/" subnet;
      message = "beacon needs lan.address, lan.gateway and lan.subnet (CIDR): fill them in with sudoedit /var/secrets/dotfiles/vars.toml";
    }
  ];

  imports =
  [
    ./hardware.nix
    ./storage.nix
  ];

  networking.hostName = "beacon";
  docker.enable = true;
  encryption.enable = false;
  services.openssh.enable = true;
  # every push to the beacon branch, see README.md
  rebuild.auto.enable = true;

  # the k3s ddns keeps the apex and *. pointed here; k3s.apps add their subdomains
  proxy =
  {
    enable = true;
    inherit domain;
    # split-horizon: blocky sends the LAN here directly
    lanSubnets = [ subnet ];
    # the records are DNS-only, so clients come straight here, not through Cloudflare
    cloudflareOnly = false;
  };

  k3s.enable = true;
  k3s.ddns.enable = true;
  k3s.apps =
  [
    "vaultwarden"
    "forgejo"
    "gatus"
    "glance"
    "pocket-id"
    "tinyauth"
    "blocky"
    "ntfy"
    "miniflux"
    "paperless"
    "jellyfin"
    "immich"
    "silverbullet"
    "linkding"
    "audiobookshelf"
    "stirling-pdf"
    "syncthing"
    "filebrowser"
    "actual"
    "wastebin"
    "searxng"
    "vikunja"
    "radicale"
    "navidrome"
    "n8n"
    "atuin"
    "changedetection"
    "mealie"
    "excalidraw"
  ];
  k3s.lanAddress = address;
  # app state and the cluster to the backup disk, daily
  k3s.backup.enable = true;
  # Beszel and Scrutiny on the host, at metrics. and disks.
  monitoring.enable = true;

  environment.systemPackages = [ pkgs.kitty.terminfo ];

  # Intel Arc: headless skips the desktop that would enable graphics.
  # mesa covers iris/ANV; iHD + oneVPL for VA-API/QSV, compute-runtime for OpenCL/Level Zero
  hardware.enableRedistributableFirmware = true;
  hardware.graphics =
  {
    enable = true;
    extraPackages = with pkgs;
    [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  # intel_gpu_top
  hardware.intel-gpu-tools.enable = true;

  # wake-on-lan on every wired NIC (also enable it in the BIOS)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="${pkgs.ethtool}/bin/ethtool -s $name wol g"
  '';
  # stop NetworkManager resetting it on connect (64 = magic)
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = 64;

  # static ip; no interface-name so it binds to whichever wired NIC is present
  networking.networkmanager.ensureProfiles.profiles.wired =
  {
    connection =
    {
      id = "wired";
      type = "ethernet";
      autoconnect-priority = 100;
    };
    ipv4 =
    {
      method = "manual";
      address1 = "${address}/${prefix},${gateway}";
      dns = "${gateway};";
    };
    ipv6.method = "auto";
  };

  system.stateVersion = "26.11";
}
