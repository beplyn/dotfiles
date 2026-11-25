{ pkgs, domain, lan, wgKeys, ... }:

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
  # every push to the beacon branch, see docs/rebuild.md
  rebuild.auto.enable = true;

  # the k3s ddns keeps the apex and *. pointed here; k3s.apps add their subdomains
  proxy =
  {
    enable = true;
    inherit domain;
    # split-horizon: blocky sends the LAN here directly; k3s pods/services arrive via CoreDNS
    lanSubnets = [ lan.subnet "10.42.0.0/16" "10.43.0.0/16" ];
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
    "chhoto"
    "audiobookshelf"
    "stirling-pdf"
    "filebrowser"
    "actual"
    "wastebin"
    "searxng"
    "vikunja"
    "radicale"
    "navidrome"
    "metube"
    "qbittorrent"
    "n8n"
    "atuin"
    "changedetection"
    "mealie"
    "excalidraw"
    "minecraft"
    "asf"
  ];
  k3s.lanAddress = lan.address;
  # Wings, mc-router and the Minecraft sync; the Panel itself is the minecraft app
  pelican.enable = true;
  # app state and the cluster to the backup disk, daily
  k3s.backup.enable = true;
  # Beszel and Scrutiny on the host, at metrics. and disks.
  monitoring.enable = true;

  # the wg0 server: the desktops dial in on 51820 and ssh to beacon over 10.100.0.1
  wireguard =
  {
    enable = true;
    address = "10.100.0.1/24";
    listenPort = 51820;
    # keys come from the vars file (scripts/wireguard); a peer with no key is left out
    peers =
    [
      {
        # anvil
        publicKey = wgKeys.anvil or "";
        allowedIPs = [ "10.100.0.2/32" ];
      }
      {
        # shulker
        publicKey = wgKeys.shulker or "";
        allowedIPs = [ "10.100.0.3/32" ];
      }
    ];
  };

  environment.systemPackages = [ pkgs.kitty.terminfo pkgs.rsync ];

  system.stateVersion = "26.11";
}
