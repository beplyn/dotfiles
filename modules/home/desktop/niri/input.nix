{
  osConfig,
  ...
}:

{
  programs.niri.settings.input =
  {
    keyboard.xkb =
    {
      inherit (osConfig.services.xserver.xkb) layout variant;
    };
    focus-follows-mouse =
    {
      enable = true;
      max-scroll-amount = "50%";
    };
  };
}
