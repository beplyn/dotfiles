{
  config,
  lib,
  pkgs,
  ...
}:

# Flatpak with Flathub, and Bazaar as the store. The sandbox only sees
# /usr/share and the store paths it is allowed to, so fonts, icons and the
# cursor get bind-mounted there and the Stylix GTK css is let in
let
  # what the bind mounts expose under /usr/share
  shared = pkgs.buildEnv
  {
    name = "flatpak-host-share";
    paths = config.fonts.packages ++
    [
      config.stylix.icons.package
      config.stylix.cursor.package
      pkgs.hicolor-icon-theme
      pkgs.adwaita-icon-theme
    ];
    pathsToLink = [ "/share/fonts" "/share/icons" ];
  };

  roBind = path:
  {
    device = path;
    fsType = "fuse.bindfs";
    options = [ "ro" "resolve-symlinks" "x-gvfs-hide" ];
  };

  # ~/.config/gtk-*.0 link into /nix/store, so that has to be visible too
  overrides = lib.generators.toINI { }
  {
    Context.filesystems = lib.concatStringsSep ";"
    [
      "/nix/store:ro"
      "xdg-config/gtk-3.0:ro"
      "xdg-config/gtk-4.0:ro"
      "xdg-config/fontconfig:ro"
      "~/.icons:ro"
    ];
    Environment.XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
  };
in
{
  services.flatpak.enable = true;

  # system-wide Flathub, retried until the network is up
  systemd.services.flatpak-flathub =
  {
    description = "Add the Flathub remote";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ config.services.flatpak.package ];
    script = "flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
    serviceConfig =
    {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 30;
    };
  };

  # applies to every app; `flatpak override --user` still works on top
  systemd.tmpfiles.rules =
  [
    "d /var/lib/flatpak/overrides 0755 root root -"
    "L+ /var/lib/flatpak/overrides/global - - - - ${pkgs.writeText "flatpak-global-overrides" overrides}"
  ];

  fonts.fontDir.enable = true;
  system.fsPackages = [ pkgs.bindfs ];
  fileSystems."/usr/share/fonts" = roBind "${shared}/share/fonts";
  fileSystems."/usr/share/icons" = roBind "${shared}/share/icons";

  # Bazaar's background service is D-Bus activated (search, update checks)
  environment.systemPackages = [ pkgs.bazaar ];
  services.dbus.packages = [ pkgs.bazaar ];
  systemd.packages = [ pkgs.bazaar ];
}
