# Floating capsule bar; panels open in Quickshell over IPC.
{
  config,
  lib,
  osConfig,
  ...
}:

let
  t = config.themes.shell;
  gap = t.gaps;
  signals = config.lib.haku.waybarSignals;
  cava = lib.getExe config.lib.haku.cava.cavaVisualizer;
  laptop = osConfig.laptop.enable;

  # qs ipc call as an on-click string
  ipc = target: fn: args: lib.escapeShellArgs (config.lib.haku.ipc target fn ++ args);
  panel = name: ipc "panels" "toggle" [ name ];

  # Nerd Font glyph from codepoint (no \u in Nix)
  glyph =
    cp:
    let
      hex = n: lib.fixedWidthString 4 "0" (lib.toHexString n);
      u = n: "\\u${hex n}";
      v = cp - 65536;
    in
    builtins.fromJSON ''"${
      if cp < 65536 then u cp else u (55296 + v / 1024) + u (56320 + lib.mod v 1024)
    }"'';
  glyphs = map glyph;

in
{
  # Stylix's waybar CSS fights the capsule
  stylix.targets.waybar.enable = false;

  programs.waybar =
  {
    enable = true;
    systemd.enable = true;

    settings.main =
    {
      layer = "top";
      position = "top";
      height = 36;
      margin-top = gap;
      margin-left = gap;
      margin-right = gap;
      spacing = 4;

      # the clock alone in the middle, so music starting or a recording
      # can't push it off centre
      modules-left =
      [
        "custom/launcher"
        "ext/workspaces"
        "hyprland/window"
        "mpris"
        "custom/cava"
      ];
      modules-center = [ "clock" ];
      modules-right =
      [
        "custom/recorder"
        "group/hardware"
        "privacy"
        "group/status"
        "tray"
        "custom/notifications"
        "custom/control"
      ];

      "custom/launcher" =
      {
        format = glyph 62227; # nf-linux-nixos
        tooltip = false;
        on-click = panel "launcher";
      };

      # hyprland/workspaces clicks send hyprlang dispatches, which the Lua
      # config rejects; ext-workspace switches over the protocol
      "ext/workspaces" =
      {
        format = "{name}";
        on-click = "activate";
      };

      "hyprland/window" =
      {
        format = "{title}";
        max-length = 48;
        separate-outputs = true;
        icon = false;
      };

      mpris =
      {
        format = "{player_icon} {title}";
        format-paused = "{status_icon} <i>{title}</i>";
        title-len = 28;
        player-icons.default = glyph 984922; # music
        status-icons.paused = glyph 61516; # pause
        tooltip-format = "{artist} — {album}";
      };

      "custom/cava" =
      {
        exec = cava;
        format = "{}";
        tooltip = false;
        return-type = "text";
      };

      clock =
      {
        format = "${glyph 983376}  {:%a %d  %H:%M}"; # clock-outline
        tooltip = false;
        on-click = panel "dashboard";
        # the terminal calendar (calendar.nix)
        on-click-right = lib.escapeShellArgs config.lib.haku.calendar.open;
      };

      "custom/recorder" =
      {
        exec = ipc "recorder" "status" [ ];
        return-type = "json";
        signal = signals.recorder;
        format = "${glyph 984138} {}";
        # hide when `status` is empty
        hide-empty-text = true;
        tooltip = false;
        on-click = ipc "recorder" "stop" [ ];
      };

      "group/hardware" =
      {
        orientation = "horizontal";
        modules =
        [
          "cpu"
          "memory"
          "temperature"
        ];
      };
      cpu =
      {
        format = "${glyph 62171} {usage}%";
        interval = 2;
        states =
        {
          warning = 70;
          critical = 90;
        };
        on-click = panel "cpu";
      };
      memory =
      {
        format = "${glyph 61381} {percentage}%";
        interval = 2;
        tooltip-format = "{used:0.1f} / {total:0.1f} GiB";
        states =
        {
          warning = 75;
          critical = 90;
        };
        on-click = panel "memory";
      };
      temperature =
      {
        # CPU package: k10temp (AMD) or coretemp (Intel); thermal_zone0 is a fixed 20° on shulker
        hwmon-path-abs =
        [
          "/sys/devices/pci0000:00/0000:00:18.3/hwmon"
          "/sys/devices/platform/coretemp.0/hwmon"
        ];
        input-filename = "temp1_input";
        critical-threshold = 85;
        format = "${glyph 62153} {temperatureC}°";
        on-click = panel "temperature";
      };

      # only shown while the screen is shared; the mic lives in the control center
      privacy =
      {
        icon-size = 14;
        icon-spacing = 6;
        modules =
        [
          { type = "screenshare"; }
        ];
      };

      "group/status" =
      {
        orientation = "horizontal";
        modules =
        [
          "network"
          "bluetooth"
        ]
        ++ lib.optional laptop "battery";
      };
      # type only; details in the control center
      network =
      {
        format-wifi = "{icon}";
        format-ethernet = glyph 983552; # ethernet
        format-linked = glyph 983552;
        format-disconnected = glyph 985390; # wifi-strength-off
        format-disabled = glyph 985390;
        format-icons = glyphs
        [
          985391 # wifi-strength-outline
          985375
          985378
          985381
          985384
        ];
        tooltip-format-wifi = "Wi-Fi · {essid} · {signalStrength}%";
        tooltip-format-ethernet = "Ethernet · {ifname} · {ipaddr}";
        tooltip-format-linked = "Ethernet · {ifname} · no address";
        tooltip-format-disconnected = "Offline";
        tooltip-format-disabled = "Offline";
        on-click = panel "control";
      };
      # only shown while a device is connected
      bluetooth =
      {
        format = "";
        format-disabled = "";
        format-off = "";
        format-connected = "${glyph 983217} {num_connections}";
        format-no-controller = "";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}";
        on-click = panel "control";
      };
      battery =
      {
        format = "{icon} {capacity}%";
        format-charging = "${glyph 983172} {capacity}%";
        format-icons = glyphs
        [
          983162
          983163
          983164
          983165
          983166
          983167
          983168
          983169
          983170
          983161
        ];
        states =
        {
          warning = 30;
          critical = 15;
        };
        tooltip-format = "{timeTo}";
        # charge and its last hours (quickshell battery panel)
        on-click = panel "battery";
      };

      tray =
      {
        icon-size = 16;
        spacing = 8;
      };

      "custom/notifications" =
      {
        exec = ipc "notifications" "status" [ ];
        return-type = "json";
        signal = signals.notifications;
        format = "{icon}";
        # hidden when empty; dnd stays visible
        format-icons =
        {
          none = "";
          notification = glyph 983198; # bell-ring
          dnd-none = glyph 983195; # bell-off
          dnd-notification = glyph 983195;
        };
        on-click = ipc "notifications" "toggle" [ ];
        on-click-right = ipc "notifications" "toggleDnd" [ ];
      };

      "custom/control" =
      {
        format = glyph 984211; # cog
        tooltip = false;
        on-click = panel "control";
      };
    };

    # palette, glass, radius, fonts; layout in style.css
    style = ''
      ${t.css}
      @define-color glass alpha(@background, ${toString (t.glass - 0.17)});

      *
      {
        font-family: ${t.font};
        font-size: ${toString t.fontSize}pt;
      }

      window#waybar > box,
      tooltip,
      menu
      {
        border-radius: ${toString t.radius}px;
      }

      #custom-cava
      {
        min-width: 196px;
        color: @accent;
        text-shadow: 0 0 8px alpha(@accent, 0.65);
        letter-spacing: 1px;
      }
    ''
    + builtins.readFile ./style.css;
  };
}
