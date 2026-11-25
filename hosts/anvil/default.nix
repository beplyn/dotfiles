{ domain, wgKeys, ... }:

{
  imports = [ ./hardware.nix ./hardware-extra.nix ];

  networking.hostName = "anvil";
  # beacon's wg0 peer; it is reached at its DDNS name
  wireguard =
  {
    enable = true;
    address = "10.100.0.2/24";
    peers =
    [
      {
        publicKey = wgKeys.beacon or "";
        allowedIPs = [ "10.100.0.1/32" ];
        endpoint = "${domain}:51820";
        persistentKeepalive = 25;
      }
    ];
  };
  encryption.device = "/dev/disk/by-uuid/52043e38-4ee0-4e79-9f48-53379ba2b743";
  docker.enable = true;
  qbittorrent.enable = true;
  qbittorrent.openWebUI = false;
  gaming.enable = true;
  llm.enable = true;
  llm.extraModels =
  [
    "qwen3.6:27b-coding"
    # MoE, 23 GB: 64k ctx spills to RAM, but fast
    "qwen3.6:35b-a3b-coding"
  ];
  # 7900 XTX by uuid, not index: the iGPU is in the ROCm list too
  llm.gpu = "GPU-9fac555f6cbbbf7b";
  toolbox.enable = true;
  openrgb.enable = true;

  # the 7900 XTX; 13:00.0 is the 7800X3D's iGPU
  displayGpu = "0000:03:00.0";

  # connector names unverified (hyprctl monitors); 1080p sits left
  monitors =
  [
    {
      name = "HDMI-A-1";
      width = 1920;
      height = 1080;
      refresh = 60.0;
    }
    {
      name = "DP-1";
      width = 2560;
      height = 1440;
      refresh = 200.0;
      primary = true;
    }
  ];

  system.stateVersion = "26.11";
}
