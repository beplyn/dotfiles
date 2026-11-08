{ pkgs, ... }:

# the shell's brightness slider on external monitors: i2c-dev, and ddcutil's
# udev rule handing the buses to the seat's user
{
  boot.kernelModules = [ "i2c-dev" ];
  services.udev.packages = [ pkgs.ddcutil ];
}
