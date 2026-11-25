{ pkgs, ... }:

# GUI for the wg0 NetworkManager profile (services/wireguard.nix, wireguard.networkManager):
# nm-applet in the tray toggles it, nm-connection-editor edits it
{
  environment.systemPackages = [ pkgs.networkmanagerapplet ];

  systemd.user.services.nm-applet =
  {
    description = "NetworkManager tray applet";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig =
    {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
    };
  };
}
