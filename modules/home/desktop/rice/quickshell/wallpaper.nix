# hyprpaper draws (desktop/hyprland/services.nix); the shell's selector
# (wallpapers/WallpaperMenu.qml, Mod+W) picks; rebuild runs `wallpaper random`.
{
  config,
  lib,
  osConfig,
  pkgs,
  subst,
  themeName,
  ...
}:

let
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
  cache = "${config.xdg.cacheHome}/wallpapers";

  # every source in this theme's colours, the palette wallpaper with them,
  # and 16:9 thumbnails for the selector; built once per theme and source set
  recoloured = pkgs.runCommand "wallpapers-${themeName}"
  {
    nativeBuildInputs = [ pkgs.lutgen pkgs.imagemagick ];
  }
  ''
    export HOME="$TMPDIR"
    mkdir -p "$out/thumbs"
    ${lib.optionalString (sources != "") ''
      for src in ${sources}/*; do
        stem="$(basename "''${src%.*}")"
        lutgen apply -p ${palettes.${themeName}} -o "$out/$stem.jpg" "$src"
      done
    ''}
    magick ${config.stylix.image} -quality 95 "$out/stylix.jpg"
    for img in "$out"/*.jpg; do
      magick "$img" -resize 640x360^ -gravity center -extent 640x360 -quality 85 "$out/thumbs/$(basename "$img")"
    done
  '';

  wallpaper = pkgs.writeShellApplication
  {
    name = "wallpaper";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils ];
    text = subst { inherit cache hyprctl; } (builtins.readFile ./wallpaper.sh);
  };

  # recolor [-o DIR] IMAGE...: one copy per theme, for trying new ones
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

  waypaperSettings =
  {
    backend = "hyprpaper";
    post_command = "${lib.getExe wallpaper} set $wallpaper";
    folder = cache;
    fill = "fill";
    sort = "name";
    color = config.themes.palette.background;
    subfolders = false;
    show_hidden = false;
    show_path_in_tooltip = true;
    number_of_columns = 3;
    use_xdg_state = true;
  };
in
{
  home.packages = [ pkgs.waypaper pkgs.lutgen recolor wallpaper ];

  # writable: waypaper rewrites it on exit
  xdg.configFile."waypaper/config.ini".source = (pkgs.formats.ini { }).generate "waypaper-config"
  {
    Settings = waypaperSettings;
  };

  # file by file, so the folder stays writable for current.jpg; a theme
  # switch swaps the links, and current.jpg follows by name
  xdg.cacheFile."wallpapers" =
  {
    source = recoloured;
    recursive = true;
  };

  # until the first pick (rebuild's `wallpaper random`), the palette one
  home.activation.wallpaper = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    [ -e "${cache}/current.jpg" ] || run ln -sfn "${cache}/stylix.jpg" "${cache}/current.jpg"
  '';

  # the sources in the checkout, so new ones land in the repo
  home.file."Pictures/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/home/desktop/rice/quickshell/wallpapers";

  lib.haku.wallpaper =
  {
    inherit cache;
    bin = lib.getExe wallpaper;
  };
}
