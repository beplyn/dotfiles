# Quickshell port of hakuspace's Classic shell: the "top" waybar layout,
# the swaync control center and popups, and the wl-screenrec recorder.
# The QML lives in ./config; Nix only supplies stylix colors and store
# paths through theme.json so the QML never hardcodes either.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  t = import ../theme.nix { inherit config; };
  c = config.lib.stylix.colors.withHashtag;
  fonts = config.stylix.fonts;

  record = pkgs.writeShellApplication {
    name = "record";
    runtimeInputs = with pkgs; [
      wl-screenrec
      pulseaudio # pactl, pacat
      pipewire # pw-metadata
      libnotify
      jq
      procps
      osConfig.programs.niri.package
    ];
    text = builtins.readFile ./record.sh;
  };

  cavaConfig = (pkgs.formats.ini { }).generate "haku-cava.conf" {
    general = {
      bars = 12;
      framerate = 60;
      sleep_timer = 2;
    };
    output = {
      method = "raw";
      raw_target = "/dev/stdout";
      data_format = "ascii";
      ascii_max_range = 7;
      bar_delimiter = 59; # ';'
      frame_delimiter = 10; # '\n'
    };
  };

  bin = {
    record = lib.getExe record;
    cava = lib.getExe pkgs.cava;
    inherit cavaConfig;
    niri = lib.getExe osConfig.programs.niri.package;
    launcher = lib.getExe config.services.walker.package;
    lock = "${lib.getExe config.programs.swaylock.package} -f";
    brightnessctl = lib.getExe pkgs.brightnessctl;
    mixer = lib.getExe pkgs.pavucontrol;
    wallpaper = lib.getExe pkgs.waypaper;
    systemctl = "systemctl";
  };

  theme = {
    colors = lib.genAttrs [
      "base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07"
      "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"
    ] (base: c.${base});
    font = {
      family = fonts.monospace.name;
      size = fonts.sizes.desktop;
      popup = fonts.sizes.popups;
    };
    inherit (t) radius glass;
    inherit bin;
  };

  # Copied (not linked) so Quickshell resolves theme.json next to shell.qml
  # even though it canonicalises the config path into the store.
  shellConfig = pkgs.runCommandLocal "quickshell-haku" { } ''
    cp -r ${./config} $out
    chmod u+w $out
    cp ${pkgs.writeText "theme.json" (builtins.toJSON theme)} $out/theme.json
  '';

  qs = lib.getExe' config.programs.quickshell.package "qs";
in
{
  imports = [ ./wallpaper.nix ];

  programs.quickshell = {
    enable = true;
    configs.haku = shellConfig;
    activeConfig = "haku";
    systemd.enable = true;
  };

  # Reload the shell whenever the generated config changes.
  systemd.user.services.quickshell.Unit.X-Restart-Triggers = [ "${shellConfig}" ];

  home.packages = [
    record
    pkgs.wl-screenrec
  ];

  # Argv for `qs ipc call <target> <function>`, used by the niri binds.
  lib.haku.ipc = target: fn: [
    qs
    "-c"
    "haku"
    "ipc"
    "call"
    target
    fn
  ];
}
