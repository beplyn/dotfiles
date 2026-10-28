# awww draws the wallpaper; waypaper picks it and restores it at login.
# Transition settings match hakuspace's AWWW_OPTS.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
  waypaper = lib.getExe pkgs.waypaper;
  awww = config.services.awww.package;
in
{
  services.awww.enable = true;

  home.packages = [ pkgs.waypaper ];

  # waypaper rewrites config.ini on exit; a read-only file only makes it
  # log a warning, and the chosen wallpaper goes to its state file instead.
  xdg.configFile."waypaper/config.ini".source = (pkgs.formats.ini { }).generate "waypaper-config" {
    Settings = {
      backend = "awww";
      folder = "~/Pictures/Wallpapers";
      fill = "fill";
      sort = "name";
      color = c.base00;
      subfolders = true;
      show_hidden = false;
      show_path_in_tooltip = true;
      number_of_columns = 3;
      use_xdg_state = true;
      swww_transition_type = "random";
      swww_transition_step = 90;
      swww_transition_angle = 0;
      swww_transition_duration = 2;
      swww_transition_fps = 60;
    };
  };

  systemd.user.services.waypaper-restore = {
    Unit = {
      Description = "Restore the last waypaper wallpaper";
      After = [ "awww.service" ];
      Requires = [ "awww.service" ];
      PartOf = [ "awww.service" ];
    };
    Service = {
      Type = "oneshot";
      Environment = "PATH=${lib.makeBinPath [ awww pkgs.procps pkgs.coreutils ]}";
      # awww.service counts as started before its socket accepts requests.
      ExecStartPre = "${pkgs.bash}/bin/sh -c 'until awww query; do sleep 0.1; done'";
      ExecStart = "${waypaper} --restore";
      TimeoutStartSec = 30;
    };
    # Hang off awww rather than the session target: awww is ordered after the
    # target, and the target is implicitly ordered after everything it wants,
    # so WantedBy=<target> here formed a cycle that systemd broke by randomly
    # dropping this job or awww itself.
    Install.WantedBy = [ "awww.service" ];
  };

  home.activation.wallpaperDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Pictures/Wallpapers"
  '';
}
