{
  config,
  pkgs,
  subst,
  ...
}:

let
  t = config.themes.shell;
in
{
  # walker backend: apps, commands, clipboard history
  services.elephant =
  {
    enable = true;
    # clipboard provider signals its save loop while holding the history lock;
    # an unbuffered send deadlocks it and history stops updating
    package = pkgs.elephant.overrideAttrs (old:
    {
      patches = (old.patches or [ ]) ++ [ ./elephant-clipboard-deadlock.patch ];
    });
  };

  services.walker =
  {
    enable = true;
    systemd.enable = true;

    settings =
    {
      close_when_open = true;
      force_keyboard_focus = true;
      selection_wrap = true;
      click_to_close = true;

      placeholders =
      {
        default =
        {
          input = "Search";
          list = "Nothing found";
        };
        clipboard =
        {
          input = "Clipboard";
          list = "Clipboard is empty";
        };
      };

      providers =
      {
        default =
        [
          "desktopapplications"
          "calc"
          "runner"
          "websearch"
        ];
        empty = [ "desktopapplications" ];
        max_results = 50;
        clipboard.time_format = "relative";
      };
    };

    theme =
    {
      name = "stylix";
      style = t.css + "\n" + subst
        {
          font = t.font;
          fontSize = t.popupFontSize;
          fontSizeLarge = t.popupFontSize + 2;
          radius = t.radius;
          radiusSmall = t.radius - 6;
          radiusLarge = t.radius + 6;
          glass = t.glass;
        }
        (builtins.readFile ./walker.css);
    };
  };
}
