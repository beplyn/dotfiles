{ pkgs, domain, lan, ... }:

{
  imports =
  [
    ./hardware.nix
    ./hardware-extra.nix
    ./network.nix
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
    lanSubnets = [ lan.subnet ];
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
    "minecraft"
  ];
  k3s.lanAddress = lan.address;
  # app state and the cluster to the backup disk, daily
  k3s.backup.enable = true;
  # Beszel and Scrutiny on the host, at metrics. and disks.
  monitoring.enable = true;

  environment.systemPackages = [ pkgs.kitty.terminfo ];

  system.stateVersion = "26.11";
}
