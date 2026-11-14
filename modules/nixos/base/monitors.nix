{ lib, ... }:

# Per-host display hardware: Hyprland and greeter layout (empty on VMs) and laptop panel.
let
  monitor = lib.types.submodule
  {
    options =
    {
      name = lib.mkOption
      {
        type = lib.types.str;
        example = "DP-1";
        description = "Connector name, as listed by `hyprctl monitors`.";
      };
      width = lib.mkOption { type = lib.types.int; };
      height = lib.mkOption { type = lib.types.int; };
      refresh = lib.mkOption
      {
        type = lib.types.float;
        description = "Refresh rate in Hz; Hyprland picks the closest mode.";
      };
      primary = lib.mkOption
      {
        type = lib.types.bool;
        default = false;
        description = "Focus this output when Hyprland starts; the only one the greeter uses.";
      };
    };
  };
in
{
  options.monitors = lib.mkOption
  {
    type = lib.types.listOf monitor;
    default = [ ];
    description = "Outputs from left to right; each is placed after the previous one.";
  };

  options.displayGpu = lib.mkOption
  {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "0000:03:00.0";
    description = "PCI address of the GPU the monitors are plugged into, when there are several; linked as /dev/dri/display.";
  };

  # battery and backlight widgets in the shell
  options.laptop.enable = lib.mkEnableOption "laptop-only shell widgets";
}
