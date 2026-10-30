# awww draws, waypaper picks and restores.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  p = config.themes.palette;
  waypaper = lib.getExe pkgs.waypaper;
  awww = config.services.awww.package;
in
{
  services.awww.enable = true;

  home.packages = [ pkgs.waypaper ];

  # writable: waypaper rewrites it on exit
  xdg.configFile."waypaper/config.ini".source = (pkgs.formats.ini { }).generate "waypaper-config"
  {
    Settings =
    {
      backend = "awww";
      folder = "~/Pictures/Wallpapers";
      fill = "fill";
      sort = "name";
      color = p.background;
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

  systemd.user.services.waypaper-restore =
  {
    Unit =
    {
      Description = "Restore the last waypaper wallpaper";
      After = [ "awww.service" ];
      Requires = [ "awww.service" ];
      PartOf = [ "awww.service" ];
    };
    Service =
    {
      Type = "oneshot";
      Environment = "PATH=${lib.makeBinPath [ awww pkgs.procps pkgs.coreutils ]}";
      # awww is "started" before its socket is ready
      ExecStartPre = "${pkgs.bash}/bin/sh -c 'until awww query; do sleep 0.1; done'";
      ExecStart = "${waypaper} --restore";
      TimeoutStartSec = 30;
    };
    # WantedBy awww, not the session target (avoids a cycle)
    Install.WantedBy = [ "awww.service" ];
  };

  home.activation.wallpaperDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Pictures/Wallpapers"
  '';
}
