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
    ./hardware-extra.nix
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
