{ lib, osConfig, ... }:

{
  wayland.windowManager.hyprland.settings.monitor = map (
    monitor:
    "${monitor.name},${toString monitor.width}x${toString monitor.height}@${toString monitor.refresh},auto,1"
  ) osConfig.monitors;
}
