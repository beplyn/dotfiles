{ pkgs, ... }:

let
  address = "192.168.2.200";
  subnet = "192.168.2.0/24";
in
{
  imports =
  [
    ./hardware.nix
    ./storage.nix
  ];

  networking.hostName = "beacon";
  docker.enable = true;
  encryption.enable = false;
  forgejo.enable = false;
  services.openssh.enable = true;

  # switches only to master-signed commits (else a TOTP code); sudo needs password + TOTP
  rebuildGate =
  {
    enable = true;
    # password-only sudo until `sudo rebuild-gate init` has a TOTP seed; false after that
    allowUnenrolled = true;
    autoDeploy =
    {
      enable = true;
      remote = "https://codeberg.org/beplyn/dotfiles.git";
    };
  };

  # the k3s ddns keeps the apex and *. pointed here; k3s.apps add their subdomains
  proxy =
  {
    enable = true;
    domain = "beplyn.dev";
    # split-horizon: blocky sends the LAN here directly
    lanSubnets = [ subnet ];
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
    "blocky"
    "ntfy"
    "miniflux"
    "paperless"
    "jellyfin"
    "immich"
  ];
  k3s.lanAddress = address;
  # app state and the cluster to the backup disk, daily
  k3s.backup.enable = true;

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
      address1 = "${address}/24,192.168.2.1";
      dns = "192.168.2.1;";
    };
    ipv6.method = "auto";
  };

  system.stateVersion = "26.11";
}
