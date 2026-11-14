{ lib, ... }:

# Per-host: a battery and a backlight, read by the shell (quickshell, waybar).
{
  options.laptop.enable = lib.mkEnableOption "laptop-only shell widgets";
}
