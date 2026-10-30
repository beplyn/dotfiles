{ lib, ... }:

# Per-host display layout, set in hosts/<host>/default.nix and turned into
# niri outputs by modules/home/wm/niri/outputs.nix. Hosts that leave it
# empty (VMs) let niri pick modes and follow the guest agent's resizes.
let
  monitor = lib.types.submodule
  {
    options =
    {
      name = lib.mkOption
      {
        type = lib.types.str;
        example = "DP-1";
        description = "Connector name, as listed by `niri msg outputs`.";
      };
      width = lib.mkOption { type = lib.types.int; };
      height = lib.mkOption { type = lib.types.int; };
      refresh = lib.mkOption
      {
        type = lib.types.float;
        description = "Refresh rate in Hz; niri picks the closest mode.";
      };
      primary = lib.mkOption
      {
        type = lib.types.bool;
        default = false;
        description = "Focus this output when niri starts.";
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
}
