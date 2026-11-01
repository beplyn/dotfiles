# Floating capsule bar; panels open in Quickshell over IPC.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  t = config.themes.shell;
  gap = config.programs.niri.settings.layout.gaps;
  niri = lib.getExe osConfig.programs.niri.package;
  signals = config.lib.haku.waybarSignals;
  laptop = osConfig.laptop;

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

      modules-left =
      [
        "custom/launcher"
        "niri/workspaces"
        "niri/window"
      ];
      modules-center =
      [
        "mpris"
        "clock"
        "custom/recorder"
      ];
      modules-right =
      [
        "group/hardware"
        "idle_inhibitor"
        "group/status"
        "tray"
        "custom/notifications"
        "custom/control"
      ];

      "custom/launcher" =
      {
        format = glyph 62227; # nf-linux-nixos
        tooltip = false;
        on-click = lib.getExe config.services.walker.package;
      };

      "niri/workspaces" =
      {
        format = "{index}";
        on-scroll-up = "${niri} msg action focus-workspace-up";
        on-scroll-down = "${niri} msg action focus-workspace-down";
      };

      "niri/window" =
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
        # play/pause, prev, next
      };

      clock =
      {
        format = "${glyph 983376}  {:%a %d  %H:%M}"; # clock-outline
        tooltip = false;
        on-click = panel "dashboard";
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
      # AMD CPU sensor
      temperature =
      {
        # CPU package sensor, first that exists: AMD k10temp, Intel coretemp; without
        # either waybar falls back to thermal_zone0, a fixed 20° ACPI zone on compass
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

      idle_inhibitor =
      {
        format = "{icon}";
        format-icons =
        {
          activated = glyph 983414; # coffee
          deactivated = glyph 984242; # sleep
        };
        tooltip-format-activated = "Staying awake";
        tooltip-format-deactivated = "Idle allowed";
      };

      "group/status" =
      {
        orientation = "horizontal";
        modules =
        [
          "network"
          "bluetooth"
          "wireplumber"
        ]
        ++ lib.optionals laptop
        [
          "battery"
          "power-profiles-daemon"
        ];
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
      bluetooth =
      {
        format = glyph 983215; # bluetooth
        format-disabled = glyph 983218; # bluetooth-off
        format-connected = "${glyph 983217} {num_connections}";
        format-no-controller = "";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}";
        on-click = panel "control";
      };
      wireplumber =
      {
        format = "{icon} {volume}%";
        format-muted = glyph 984927; # volume-off
        format-icons = glyphs
        [
          61478
          61479
          61480
        ];
        scroll-step = 5;
        on-click = panel "control";
        on-click-right = lib.getExe pkgs.pavucontrol;
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
        on-click = panel "control";
      };
      # click cycles profiles
      power-profiles-daemon =
      {
        format = "{icon}";
        format-icons =
        {
          power-saver = glyph 61548; # leaf
          balanced = glyph 62030; # balance-scale
          performance = glyph 61671; # bolt
          default = glyph 62030;
        };
        tooltip-format = "Power mode: {profile}";
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
        format-icons =
        {
          none = glyph 983194; # bell
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
      @define-color glass alpha(@base, ${toString (t.glass - 0.17)});

      * {
        font-family: ${t.font};
        font-size: ${toString t.fontSize}pt;
      }

      window#waybar > box,
      tooltip,
      menu {
        border-radius: ${toString t.radius}px;
      }
    ''
    + builtins.readFile ./style.css;
  };
}
