{ lib, ... }:

# greetd running ReGreet inside cage. Stylix's regreet target supplies the
# GTK theme, colours, font, cursor and icons, so only layout lives here.
{
  services.displayManager.regreet =
  {
    enable = true;
    settings =
    {
      # Stylix derives this from polarity, which is unset; every theme we
      # ship is dark.
      GTK.application_prefer_dark_theme = lib.mkForce true;
      appearance.greeting_msg = "⚞^. .^⚟";
      widget.clock =
      {
        format = "%a, %d %b  %H:%M";
        resolution = "1s";
      };
    };
  };
}
