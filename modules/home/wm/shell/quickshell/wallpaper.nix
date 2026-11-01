# awww draws, waypaper picks and restores; rebuild runs wallpaper-pick.
{
  config,
  lib,
  pkgs,
  themeName,
  ...
}:

let
  p = config.themes.palette;
  waypaper = lib.getExe pkgs.waypaper;
  awww = config.services.awww.package;

  # lutgen palette per theme, matching the Stylix schemes
  palettes =
  {
    catppuccin = "catppuccin-mocha";
    gruvbox = "gruvbox-dark-hard";
    nord = "nord";
  };

  # uncoloured sources; git skips an empty folder
  sources = lib.optionalString (builtins.pathExists ./wallpapers) "${./wallpapers}";
  cache = "${config.xdg.cacheHome}/wallpaper";

  # recolor [-o DIR] IMAGE...: one copy per theme
  recolor = pkgs.writeShellApplication
  {
    name = "recolor";
    runtimeInputs = [ pkgs.lutgen ];
    text = ''
      out=
      if [ "''${1:-}" = "-o" ]; then
        out="$2"
        shift 2
        mkdir -p "$out"
      fi
      if [ $# -eq 0 ]; then
        echo "usage: recolor [-o DIR] IMAGE..." >&2
        exit 1
      fi
      for img in "$@"; do
        stem="$(basename "''${img%.*}")"
        dir="''${out:-$(dirname "$img")}"
        ${lib.concatLines (lib.mapAttrsToList (theme: palette: ''
          lutgen apply -p ${palette} -o "$dir/$stem-${theme}.png" "$img"
        '') palettes)}
      done
    '';
  };

  # random source in the current theme's colours, else the Stylix wallpaper
  wallpaper-pick = pkgs.writeShellApplication
  {
    name = "wallpaper-pick";
    runtimeInputs = [ pkgs.lutgen pkgs.waypaper awww pkgs.coreutils pkgs.findutils ];
    text = ''
      mkdir -p "${cache}"
      src=
      if [ -n "${sources}" ]; then
        src="$(find -L "${sources}" -type f \
          \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)"
      fi
      if [ -n "$src" ]; then
        img="${cache}/$(basename "''${src%.*}")-${themeName}.png"
        # cached per source and theme
        [ -e "$img" ] || lutgen apply -p ${palettes.${themeName}} -o "$img" "$src"
      else
        img="${config.stylix.image}"
      fi
      ln -sfn "$img" "${cache}/current.png"
      # no session (e.g. a TTY): the lock screen still follows the symlink
      if awww query >/dev/null 2>&1; then
        waypaper --wallpaper "${cache}/current.png"
      fi
    '';
  };
in
{
  services.awww.enable = true;

  home.packages = [ pkgs.waypaper pkgs.lutgen recolor wallpaper-pick ];

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
