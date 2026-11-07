# awww draws, waypaper picks and restores; rebuild runs wallpaper-pick.
# Hyprland draws with hyprpaper instead (desktop/hyprland/services.nix).
{
  config,
  lib,
  osConfig,
  pkgs,
  themeName,
  ...
}:

let
  p = config.themes.palette;
  waypaper = lib.getExe pkgs.waypaper;
  awww = config.services.awww.package;
  hyprctl = lib.getExe' osConfig.programs.hyprland.package "hyprctl";
  # awww and its restore stand down for hyprpaper
  notHyprland = "${pkgs.bash}/bin/sh -c '[ \"$(${lib.getExe config.lib.haku.wm} name)\" != hyprland ]'";

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
  # rebuild copies new ones from here into ./wallpapers
  folder = "${config.home.homeDirectory}/Pictures/Wallpapers";

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
    runtimeInputs = [ pkgs.lutgen pkgs.waypaper awww pkgs.coreutils pkgs.findutils config.lib.haku.wm ];
    text = ''
      mkdir -p "${cache}"
      src=
      ${lib.optionalString (sources != "") ''
        src="$(find -L "${sources}" -type f \
          \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)"
      ''}
      if [ -n "$src" ]; then
        img="${cache}/$(basename "''${src%.*}")-${themeName}.png"
        # cached per source and theme
        [ -e "$img" ] || lutgen apply -p ${palettes.${themeName}} -o "$img" "$src"
      else
        img="${config.stylix.image}"
      fi
      ln -sfn "$img" "${cache}/current.png"
      # no session (e.g. a TTY): the lock screen still follows the symlink
      if [ "$(wm name)" = hyprland ]; then
        # hyprpaper reads the symlink when it starts; this swaps it live
        ${hyprctl} hyprpaper wallpaper ",$(readlink -f "${cache}/current.png"),cover" >/dev/null || true
      elif awww query >/dev/null 2>&1; then
        waypaper --wallpaper "${cache}/current.png"
      fi
    '';
  };

  # waypaper on hyprpaper, with its own config and state so the other
  # sessions' awww backend stays as it is; picks become the lock screen's too
  hyprlandConfig = (pkgs.formats.ini { }).generate "waypaper-hyprland-config"
  {
    Settings = waypaperSettings //
    {
      backend = "hyprpaper";
      post_command = "ln -sfn $wallpaper ${cache}/current.png";
    };
  };
  waypaper-hyprland = pkgs.writeShellApplication
  {
    name = "waypaper-hyprland";
    runtimeInputs = [ pkgs.waypaper pkgs.coreutils ];
    text = ''
      state="${config.xdg.stateHome}/waypaper"
      mkdir -p "$state"
      exec waypaper --config-file ${hyprlandConfig} --state-file "$state/hyprland.ini" "$@"
    '';
  };

  waypaperSettings =
  {
    backend = "awww";
    inherit folder;
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
in
{
  services.awww.enable = true;

  home.packages = [ pkgs.waypaper pkgs.lutgen recolor wallpaper-pick waypaper-hyprland ];

  # writable: waypaper rewrites it on exit
  xdg.configFile."waypaper/config.ini".source = (pkgs.formats.ini { }).generate "waypaper-config"
  {
    Settings = waypaperSettings;
  };

  systemd.user.services.awww.Service.ExecCondition = notHyprland;

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
      ExecCondition = notHyprland;
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
    run mkdir -p "${folder}"
  '';
}
