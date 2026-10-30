# greetd + ReGreet in cage, themed by Stylix. Patched so the password field shows right away.
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
