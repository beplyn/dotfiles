{
  config,
  lib,
  osConfig,
  ...
}:

# host monitors -> hl.monitor specs, left to right, for session.lua
let
  place = acc: m:
  {
    x = acc.x + m.width;
    monitors = acc.monitors ++
    [
      {
        output = m.name;
        mode = "${toString m.width}x${toString m.height}@${toString m.refresh}";
        position = "${toString acc.x}x0";
        scale = 1;
      }
    ];
  };
  primary = lib.findFirst (m: m.primary) null osConfig.monitors;
in
{
  wayland.windowManager.hyprland.extraLuaFiles = config.lib.haku.hyprlandData "outputs"
  {
    inherit ((lib.foldl' place { x = 0; monitors = [ ]; } osConfig.monitors)) monitors;
    primary = if primary != null then primary.name else null;
  };
}
