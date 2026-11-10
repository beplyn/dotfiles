{ lib, ... }:

# Per-host touchpad scrolling, read by Hyprland (hyprland/settings.nix).
{
  options.touchpad =
  {
    naturalScroll = lib.mkOption
    {
      type = lib.types.bool;
      default = false;
      description = "Content follows the fingers (\"reversed\" scrolling).";
    };

    scrollFactor = lib.mkOption
    {
      type = lib.types.float;
      default = 1.0;
      description = "Multiplier on two-finger scroll distance.";
    };
  };
}
