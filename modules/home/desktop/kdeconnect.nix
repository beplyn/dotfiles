{
  # kdeconnectd as a user service on graphical-session.target, so it runs in
  # every session without the app open; the NixOS side opens the firewall
  # (nixos/desktop/kdeconnect.nix)
  services.kdeconnect.enable = true;
}
