{ pkgs, ... }:

# Plumbing every desktop host needs: keyring, mounts, Bluetooth, file picker.
{
  # Unlock gnome-keyring with the login password so browsers and Proton Mail
  # don't ask for it each session.
  security.pam.services.ly.enableGnomeKeyring = true;

  # gvfs: trash and network locations; udisks2: removable drives.
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Battery and power-profile sources for the quickshell bar.
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # The GNOME portal's file chooser is provided by Nautilus; without it,
  # upload/attach/save dialogs fail to open.
  environment.systemPackages = [ pkgs.nautilus ];
}
