{
  inputs,
  pkgs,
  ...
}:

{
  home.packages = [
    inputs.netspd.packages.${pkgs.system}.default
  ];

  xdg.configFile."netspd/config.toml".text = ''
    refresh_rate = 60
    provider = "librespeed"
    animation_speed = 1.0
    notify = true
    servers = []

    [engine]
    ping_samples = 10
    ping_interval_ms = 100
    duration_secs = 15
    connections = 4
    timeout_secs = 15
    upload_chunk_kb = 2560

    [wallpaper]
    kind = "none"
  '';
}
