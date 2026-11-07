{ lib, ... }:

# Per-host touchpad scrolling, the same in every compositor (niri, sway,
# mango and Hyprland read it); each one's own default differs.
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
