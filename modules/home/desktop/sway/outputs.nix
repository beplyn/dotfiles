{
  lib,
  osConfig,
  ...
}:

# host monitors -> sway outputs, left to right
let
  place = acc: m:
  {
    x = acc.x + m.width;
    outputs = acc.outputs //
    {
      ${m.name} =
      {
        mode = "${toString m.width}x${toString m.height}@${toString m.refresh}Hz";
        position = "${toString acc.x} 0";
      };
    };
  };
  primary = lib.findFirst (m: m.primary) null osConfig.monitors;
in
{
  wayland.windowManager.sway.config =
  {
    output = (lib.foldl' place { x = 0; outputs = { }; } osConfig.monitors).outputs;
    startup = lib.optional (primary != null) { command = "swaymsg focus output ${primary.name}"; };
  };
}
