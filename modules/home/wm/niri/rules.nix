{
  programs.niri.settings.window-rules =
  [
    {
      matches =
      [
        { app-id = "^equibop$"; }
        { app-id = "^steam$"; }
      ];
      opacity = 0.75;
    }

    # Steam's toast popups are separate windows; pin only those to the top right.
    {
      matches =
      [
        {
          app-id = "^steam$";
          title = "^notificationtoasts_\\d+_desktop$";
        }
      ];
      open-floating = true;
      open-focused = false;
      default-floating-position =
      {
        x = 10;
        y = 10;
        relative-to = "top-right";
      };
    }

    {
      matches = [ { app-id = "^com.gabm.satty$"; } ];
      open-floating = true;
    }
  ];
}
