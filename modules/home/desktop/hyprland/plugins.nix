{
  config,
  lib,
  pkgs,
  subst,
  ...
}:

# Plugins and the rest of the ecosystem around them, coloured from Stylix:
# hyprtasking's overview, hyprfocus, borders-plus-plus, hyprsplit's
# per-monitor workspaces, pyprland's dropdown terminal and zoom, hyprshade
# with a palette shader, and Bibata as a hyprcursor. plugins.lua and
# workspaces.lua configure them.
let
  c = config.lib.stylix.colors;
  cursor = config.stylix.cursor;
  wezterm = lib.getExe config.programs.wezterm.package;

  # base0X -> "vec3(r, g, b) / 255.0", for the shader
  vec3 = n: "vec3(${c."${n}-rgb-r"}.0, ${c."${n}-rgb-g"}.0, ${c."${n}-rgb-b"}.0) / 255.0";

  # SVG cursors, sharp at any scale; Stylix's xcursor theme stays for
  # everything outside Hyprland
  bibataHyprcursor = pkgs.stdenvNoCC.mkDerivation
  {
    pname = "bibata-hyprcursor";
    version = "1.1";
    src = pkgs.fetchzip
    {
      url = "https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/v1.1/hypr_Bibata-Modern-Classic.tar.gz";
      hash = "sha256-bR7Op9gtadeVt4ohqkkfK3QqD8iA0kcNwWEdEoZjPKU=";
      stripRoot = false;
    };
    installPhase = ''
      mkdir -p $out/share/icons/Bibata-Modern-Classic
      cp -r manifest.hl hyprcursors $out/share/icons/Bibata-Modern-Classic/
    '';
  };
  hyprcursor = cursor.name == "Bibata-Modern-Classic";
in
{
  wayland.windowManager.hyprland =
  {
    plugins = with pkgs.hyprlandPlugins;
    [
      # hyprtasking: off until it builds against Hyprland 0.57 (raybbian/hyprtasking#140)
      hyprfocus
      borders-plus-plus
    ];

    extraLuaFiles =
    {
      "haku/plugins" = ./plugins.lua;
      "haku/workspaces" = ./workspaces.lua;
      # the Lua library; the package's C++ plugin is the deprecated one
      "hyprsplit/init" =
      {
        content = "${pkgs.hyprlandPlugins.hyprsplit.src}/init.lua";
        autoLoad = false;
      };
    }
    // config.lib.haku.hyprlandData "plugins"
    {
      # bare hex, for rgb() strings and 0xAARRGGBB numbers
      colors = lib.genAttrs
        [
          "base00"
          "base01"
          "base05"
        ]
        (n: c.${n});
      cursor =
      {
        theme = if hyprcursor then cursor.name else null;
        size = toString cursor.size;
      };
    };
  };

  home.packages =
  [
    pkgs.hyprshade
    pkgs.pyprland
  ]
  ++ lib.optional hyprcursor bibataHyprcursor;

  # Mod+Alt+S: the screen in two tones of the palette
  xdg.configFile."hypr/shaders/palette.glsl".text = subst
    {
      background = vec3 "base00";
      foreground = vec3 "base05";
    }
    (builtins.readFile ./palette.glsl);

  # Mod+Alt+Return drops a terminal from the top, Mod+Alt+Z zooms
  xdg.configFile."pypr/config.toml".source = (pkgs.formats.toml { }).generate "pypr-config.toml"
  {
    pyprland.plugins =
    [
      "scratchpads"
      "magnify"
    ];
    scratchpads.term =
    {
      command = "${wezterm} start --class haku-dropdown";
      class = "haku-dropdown";
      animation = "fromTop";
      size = "75% 60%";
      margin = 50;
    };
    magnify.factor = 2.0;
  };

  systemd.user.services.pyprland =
  {
    Unit =
    {
      Description = "pyprland, Hyprland's scratchpads and zoom";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service =
    {
      ExecStart = lib.getExe' pkgs.pyprland "pypr";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
