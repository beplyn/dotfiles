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

  # battery and power profiles for the bar
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Nautilus provides the portal file chooser
  environment.systemPackages = [ pkgs.nautilus ];
}
