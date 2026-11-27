{ pkgs, ... }:

# GUI for the wg0 NetworkManager profile (services/wireguard.nix, wireguard.networkManager):
# the VPN toggle is in the control center, nm-connection-editor edits it
{
  environment.systemPackages = [ pkgs.networkmanagerapplet ];
}
