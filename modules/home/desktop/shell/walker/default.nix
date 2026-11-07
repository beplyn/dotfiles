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
  # walker backend: apps and commands; the clipboard is cliphist and the
  # quickshell panel (shell/clipboard), so elephant has no provider watching it
  services.elephant =
  {
    enable = true;
    package = pkgs.elephant.override
    {
      enabledProviders =
      [
        "1password"
        "aptpackages"
        "archlinuxpkgs"
        "bitwarden"
        "bluetooth"
        "bookmarks"
        "calc"
        "desktopapplications"
        "dnfpackages"
        "files"
        "menus"
        "niriactions"
        "nirisessions"
        "playerctl"
        "protonpass"
        "providerlist"
        "runner"
        "snippets"
        "symbols"
        "todo"
        "unicode"
        "websearch"
        "windows"
        "wireplumber"
      ];
    };
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
