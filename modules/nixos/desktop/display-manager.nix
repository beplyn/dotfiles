# greetd + ReGreet in cage, themed by Stylix. Patched for the layout: clock top right, card
# with the avatar on its right, session gear and power icons in the bottom-right corner.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  p = config.themes.palette;
  mono = config.stylix.fonts.monospace.name;
  sans = config.stylix.fonts.sansSerif.name;

  # same blur rebuild applies to wallpaper-pick's result
  fallback = pkgs.runCommand "greeter-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick ${config.stylix.image} -resize 1920x1080^ -filter Gaussian -blur 0x20 -level 0%,100%,0.85 "png24:$out"
  '';
  snowflake = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake.png";
in
{
  # rebuild copies a blurred wallpaper-pick result and the rendered ~/.pfp here (the greeter
  # can't read homes); the blurred Stylix wallpaper and the snowflake until then
  systemd.tmpfiles.rules =
  [
    "d /var/lib/wallpaper 0755 root root -"
    "C /var/lib/wallpaper/current.png 0644 root root - ${fallback}"
    "d /var/lib/AccountsService/icons 0775 root root -"
    "C /var/lib/AccountsService/icons/${username} 0644 root root - ${snowflake}"
  ];

  services.displayManager.regreet =
  {
    enable = true;
    package = pkgs.regreet.overrideAttrs (old:
    {
      patches = (old.patches or [ ]) ++ [ ./regreet-layout.patch ];
    });
    settings =
    {
      skip_selection = true;
      background =
      {
        path = lib.mkForce "/var/lib/wallpaper/current.png";
        fit = "Cover";
      };
      appearance.greeting_msg = "⚞^. .^⚟";
      # the clock label takes Pango markup
      widget.clock =
      {
        format = ''<span font_family="${mono}" font_weight="bold" font_size="64pt">%H:%M</span>''
          + "\n"
          + ''<span font_family="${sans}" font_size="18pt">%A, %d %B</span>'';
        resolution = "1s";
      };
      # greeter runs unprivileged; logind lets the seat's session reboot
      commands =
      {
        reboot =
        [
          "systemctl"
          "reboot"
        ];
        poweroff =
        [
          "systemctl"
          "poweroff"
        ];
      };
    };
  };

  # appended to Stylix's ReGreet colours
  stylix.targets.regreet.extraCss = ''
    .login-card
    {
      background-color: alpha(${p.background}, 0.55);
      border: 1px solid alpha(${p.surface}, 0.9);
      border-radius: 18px;
      box-shadow: 0 8px 32px alpha(black, 0.35);
    }

    .login-card .greeting
    {
      font-size: 18pt;
      font-weight: bold;
    }

    .login-card entry,
    .login-card combobox button
    {
      min-height: 40px;
      border-radius: 10px;
      background-color: alpha(${p.surface}, 0.6);
    }

    .login-card button.login-button
    {
      min-height: 40px;
      border-radius: 10px;
      font-weight: bold;
      background-color: ${p.accent};
      color: ${p.background};
    }

    .login-card button.login-button:hover
    {
      background-color: mix(${p.accent}, ${p.foreground}, 0.15);
    }

    .avatar
    {
      border: 3px solid ${p.accent};
      border-radius: 9999px;
      box-shadow: 0 8px 32px alpha(black, 0.35);
      background-color: alpha(${p.background}, 0.55);
    }

    .clock
    {
      background: none;
      border: none;
      box-shadow: none;
      color: ${p.foreground};
      text-shadow: 0 2px 12px alpha(black, 0.5);
    }

    .corner button
    {
      min-width: 40px;
      min-height: 40px;
      padding: 0;
      border-radius: 9999px;
      background-color: alpha(${p.background}, 0.55);
      color: ${p.foreground};
    }

    .corner button:hover
    {
      background-color: alpha(${p.surface}, 0.9);
    }

    .corner button.destructive-action:hover
    {
      background-color: ${p.error};
      color: ${p.background};
    }
  '';
}
