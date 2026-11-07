{
  config,
  lib,
  pkgs,
  ...
}:

# network poking and Android, on the machines I sit at
{
  options.toolbox.enable = lib.mkEnableOption "network and Android tools";

  config = lib.mkIf config.toolbox.enable
  {
    environment.systemPackages = with pkgs;
    [
      nmap
      arp-scan
      wakeonlan
      # adb and fastboot; systemd's uaccess rules cover the phone
      android-tools
      scrcpy
    ];

    # raw sockets without sudo
    security.wrappers.arp-scan =
    {
      source = lib.getExe pkgs.arp-scan;
      capabilities = "cap_net_raw+ep";
      owner = "root";
      group = "root";
    };
  };
}
