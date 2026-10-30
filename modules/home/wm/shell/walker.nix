{
  config,
  lib,
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
      style = t.css + "\n" + lib.replaceStrings
        [ "@font@" "@fontSize@" "@fontSizeLarge@" "@radius@" "@radiusSmall@" "@radiusLarge@" "@glass@" ]
        [
          t.font
          (toString t.popupFontSize)
          (toString (t.popupFontSize + 2))
          (toString t.radius)
          (toString (t.radius - 6))
          (toString (t.radius + 6))
          (toString t.glass)
        ]
        (builtins.readFile ./walker.css);
    };
  };
}
