{ pkgs, ... }:

# keyring, mounts, Bluetooth, file picker
{
  # Secret Service, unlocked on login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # gvfs: trash, network; udisks2: drives
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  hardware.bluetooth =
  {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # pairing agent for quickshell, which has none of its own; without one the
  # controller is not pairable and devices link up unbonded, with no audio
  systemd.user.services.bt-agent =
  {
    description = "Bluetooth pairing agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "bluetooth.target" ];
    serviceConfig =
    {
      ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=NoInputNoOutput";
      Restart = "on-failure";
    };
  };

  # battery and power profiles for the bar
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Nautilus provides the portal file chooser, through the gnome portal
  environment.systemPackages = [ pkgs.nautilus ];
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  # replaces hyprland's own hyprland-portals.conf, so its default is kept
  xdg.portal.config.hyprland =
  {
    default = [ "hyprland" "gtk" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "gnome" ];
  };
}
