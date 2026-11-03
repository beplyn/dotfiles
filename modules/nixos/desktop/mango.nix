{ config, ... }:

# third session next to niri and sway; config lives in home-manager (desktop/mango)
{
  programs.mango.enable = true;

  # mango starts mango-session.target itself, which pulls in waybar,
  # quickshell and co. through graphical-session.target
  systemd.packages = [ config.programs.mango.package ];
}
