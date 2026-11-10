# hyprpaper draws (desktop/hyprland/services.nix), waypaper picks; rebuild
# runs wallpaper-pick.
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
  hyprctl = lib.getExe' osConfig.programs.hyprland.package "hyprctl";

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
  # links to ./wallpapers in the checkout, so new ones land in the repo
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
    runtimeInputs = [ pkgs.lutgen pkgs.coreutils pkgs.findutils ];
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
      # hyprpaper reads the symlink when it starts; this swaps it live. No
      # session (e.g. a TTY): the lock screen still follows the symlink
      ${hyprctl} hyprpaper wallpaper ",$(readlink -f "${cache}/current.png"),cover" >/dev/null 2>&1 || true
    '';
  };

  # picks become the lock screen's too
  waypaperSettings =
  {
    backend = "hyprpaper";
    post_command = "ln -sfn $wallpaper ${cache}/current.png";
    inherit folder;
    fill = "fill";
    sort = "name";
    color = p.background;
    subfolders = true;
    show_hidden = false;
    show_path_in_tooltip = true;
    number_of_columns = 3;
    use_xdg_state = true;
  };
in
{
  home.packages = [ pkgs.waypaper pkgs.lutgen recolor wallpaper-pick ];

  # writable: waypaper rewrites it on exit
  xdg.configFile."waypaper/config.ini".source = (pkgs.formats.ini { }).generate "waypaper-config"
  {
    Settings = waypaperSettings;
  };

  home.file."Pictures/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/home/desktop/shell/quickshell/wallpapers";
}
