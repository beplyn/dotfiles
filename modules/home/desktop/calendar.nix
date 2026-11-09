# vcal, the terminal calendar (github:beplyn/vcal), and what the desktop
# needs of it: one database for the TUI, the CLI and Quickshell
# (services/Events.qml), and the command that opens the TUI, for Mod+Shift+C,
# a right click on waybar's clock and the dashboard.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  cfg = config.programs.vcal;
  p = config.themes.palette;

  # vcal's [theme] is the Base16 slots; fill them from the palette by name,
  # in palette.nix's order, so no hex or baseXX lookups live here
  names =
  [
    "background"
    "mantle"
    "surface"
    "muted"
    "subtext"
    "foreground"
    "bright"
    "brightest"
    "red"
    "orange"
    "yellow"
    "green"
    "cyan"
    "blue"
    "purple"
    "brown"
  ];
  slotOf = name: "base0${lib.toHexString (lib.lists.findFirstIndex (n: n == name) null names)}";
  theme = lib.listToAttrs (map (n: lib.nameValuePair (slotOf n) p.${n}) names);

  vcal = lib.getExe cfg.package;
  wezterm = lib.getExe config.programs.wezterm.package;
  systemdRun = lib.getExe' osConfig.systemd.package "systemd-run";

  # the TUI in a terminal, in a scope of its own so it outlives waybar or
  # quickshell restarting; arguments go to vcal (`--date <day>`). A script
  # because mango caps a bind at 255 bytes, too short for the store paths.
  open = pkgs.writeShellScriptBin "vcal-open" ''
    exec ${systemdRun} --user --scope --collect --quiet -- \
      ${wezterm} start --class vcal -- ${vcal} --db ${lib.escapeShellArg cfg.databasePath} "$@"
  '';
in
{
  programs.vcal =
  {
    enable = true;
    # the palette above, not vcal's own Stylix lookup
    stylix.enable = false;
    settings.theme = theme //
    {
      # the shell's accent (palette.nix: purple) for selection and focus,
      # so the TUI and the dashboard agree; blue for categories
      roles =
      {
        accent = slotOf "purple";
        tag = slotOf "blue";
      };
    };
  };

  home.sessionVariables.VCAL_DB = cfg.databasePath;

  lib.haku.calendar =
  {
    bin = vcal;
    db = cfg.databasePath;
    # argv that opens the TUI; append `--date <day>` to pick the day
    open = [ (lib.getExe open) ];
  };
}
