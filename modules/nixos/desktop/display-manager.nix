# greetd running ReGreet inside cage. Stylix's regreet target supplies the
# GTK theme, colours, font, cursor, icons and wallpaper, so only layout
# lives here.
{
  services.displayManager.regreet =
  {
    enable = true;
    settings =
    {
      appearance.greeting_msg = "⚞^. .^⚟";
      widget.clock =
      {
        format = "%a, %d %b  %H:%M";
        resolution = "1s";
      };
    };
  };
}
