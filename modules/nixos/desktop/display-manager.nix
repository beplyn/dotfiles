# greetd + ReGreet in cage, themed by Stylix. Patched so the password field shows right away.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # same blur rebuild applies to wallpaper-pick's result
  fallback = pkgs.runCommand "greeter-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick ${config.stylix.image} -resize 1920x1080^ -blur 0x8 "png24:$out"
  '';
in
{
  # rebuild copies a blurred wallpaper-pick result here (the greeter can't read ~/.cache);
  # the blurred Stylix wallpaper until then
  systemd.tmpfiles.rules =
  [
    "d /var/lib/wallpaper 0755 root root -"
    "C /var/lib/wallpaper/current.png 0644 root root - ${fallback}"
  ];

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
      background.path = lib.mkForce "/var/lib/wallpaper/current.png";
      appearance.greeting_msg = "⚞^. .^⚟";
      widget.clock =
      {
        format = "%a, %d %b  %H:%M";
        resolution = "1s";
      };
    };
  };
}
