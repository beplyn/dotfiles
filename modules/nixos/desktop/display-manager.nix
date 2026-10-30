# greetd running ReGreet inside cage. Stylix's regreet target supplies the
# GTK theme, colours, font, cursor, icons and wallpaper, so only layout
# lives here.
#
# Stock ReGreet shares one grid row between the session picker and the
# password entry, so the password only shows up after pressing Login. The
# patch moves the session picker into the bottom-left corner and keeps it
# there during password entry; skip_selection then starts the login for the
# last user right away, so the password field is up from the start.
{ pkgs, ... }:
{
  services.displayManager.regreet =
  {
    enable = true;
    package = pkgs.regreet.overrideAttrs (old:
    {
      patches = (old.patches or [ ]) ++ [ ./regreet-session-corner.patch ];
    });
    settings =
    {
      skip_selection = true;
      appearance.greeting_msg = "⚞^. .^⚟";
      widget.clock =
      {
        format = "%a, %d %b  %H:%M";
        resolution = "1s";
      };
    };
  };
}
