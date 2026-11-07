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
    # the host's, as in every session (nixos/desktop/touchpad.nix); niri's
    # own default reverses scrolling
    touchpad =
    {
      natural-scroll = osConfig.touchpad.naturalScroll;
      scroll-factor = osConfig.touchpad.scrollFactor;
    };
    focus-follows-mouse =
    {
      enable = true;
      max-scroll-amount = "50%";
    };
  };
}
