{
  lib,
  osConfig,
  ...
}:

# host monitors -> niri outputs, left to right
let
  place = acc: m:
  {
    x = acc.x + m.width;
    outputs = acc.outputs //
    {
      ${m.name} =
      {
        mode =
        {
          inherit (m) width height refresh;
        };
        position =
        {
          inherit (acc) x;
          y = 0;
        };
        focus-at-startup = m.primary;
      };
    };
  };
in
{
  programs.niri.settings.outputs =
    (lib.foldl' place { x = 0; outputs = { }; } osConfig.monitors).outputs;
}
