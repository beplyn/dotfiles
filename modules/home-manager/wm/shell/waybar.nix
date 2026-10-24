{
  config,
  pkgs,
  ...
}:

let
  t = import ./theme.nix { inherit config; };
in
{
  stylix.targets.waybar.enable = false;

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.main = {
      layer = "top";
      position = "top";
      height = 38;
      margin-top = 8;
      margin-left = 10;
      margin-right = 10;
      spacing = 8;

      modules-left = [
        "custom/launcher"
        "niri/workspaces"
        "niri/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "group/hardware"
        "pulseaudio"
        "network"
        "battery"
        "tray"
        "custom/notification"
      ];

      "custom/launcher" = {
        format = "";
        tooltip = false;
        on-click = "walker";
        on-click-right = "walker -m clipboard";
      };

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "";
          default = "";
        };
      };

      "niri/window" = {
        format = "{title}";
        max-length = 48;
        separate-outputs = true;
        rewrite = {
          "" = "desktop";
        };
      };

      clock = {
        format = "  {:%H:%M}";
        format-alt = "  {:%A, %d %B %Y}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "month";
          weeks-pos = "";
          on-scroll = 1;
          format = {
            months = "<span color='${config.lib.stylix.colors.withHashtag.base0E}'><b>{}</b></span>";
            weekdays = "<span color='${config.lib.stylix.colors.withHashtag.base0D}'><b>{}</b></span>";
            today = "<span color='${config.lib.stylix.colors.withHashtag.base08}'><b><u>{}</u></b></span>";
          };
        };
        actions = {
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
      };

      "group/hardware" = {
        orientation = "horizontal";
        modules = [
          "cpu"
          "memory"
        ];
      };

      cpu = {
        format = "  {usage}%";
        interval = 3;
        states = {
          warning = 70;
          critical = 90;
        };
      };

      memory = {
        format = "  {percentage}%";
        interval = 5;
        tooltip-format = "{used:0.1f} / {total:0.1f} GiB used";
        states = {
          warning = 75;
          critical = 90;
        };
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "  muted";
        format-icons.default = [
          ""
          ""
          ""
        ];
        scroll-step = 5;
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        tooltip-format = "{desc}";
      };

      network = {
        format-wifi = "  {essid}";
        format-ethernet = "󰈀  wired";
        format-linked = "󰈀  no ip";
        format-disconnected = "󰖪  offline";
        tooltip-format-wifi = "{ipaddr} · {signalStrength}%";
        tooltip-format-ethernet = "{ifname} · {ipaddr}";
        interval = 5;
      };

      battery = {
        format = "{icon}  {capacity}%";
        format-charging = "󰂄  {capacity}%";
        format-plugged = "  {capacity}%";
        format-icons = [
          "󰁺"
          "󰁼"
          "󰁾"
          "󰂀"
          "󰁹"
        ];
        states = {
          warning = 25;
          critical = 10;
        };
      };

      tray = {
        icon-size = 16;
        spacing = 10;
      };

      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "󱅫";
          none = "󰂚";
          dnd-notification = "󰂛";
          dnd-none = "󰂛";
          inhibited-notification = "󱅫";
          inhibited-none = "󰂚";
          dnd-inhibited-notification = "󰂛";
          dnd-inhibited-none = "󰂛";
        };
        return-type = "json";
        exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
        on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
        on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
        escape = true;
      };
    };

    style = ''
      ${t.css}

      * {
        font-family: ${t.font};
        font-size: ${toString t.fontSize}pt;
        min-height: 0;
        border: none;
      }

      window#waybar {
        background: transparent;
        color: @text;
      }

      tooltip {
        background: alpha(@base, 0.95);
        border: 1px solid alpha(@accent, 0.4);
        border-radius: ${toString t.radius}px;
      }

      tooltip label {
        color: @text;
      }

      /* Every top-level module is its own floating island. */
      #custom-launcher,
      #workspaces,
      #window,
      #clock,
      #hardware,
      #pulseaudio,
      #network,
      #battery,
      #tray,
      #custom-notification {
        background: alpha(@base, ${toString t.glass});
        border: 1px solid alpha(@overlay, 0.6);
        border-radius: ${toString t.radius}px;
        padding: 0 14px;
        margin: 2px 0;
        transition: all 200ms ease;
      }

      #custom-launcher {
        color: @accent;
        font-size: ${toString (t.fontSize + 3)}pt;
        padding: 0 16px 0 14px;
      }

      #custom-launcher:hover,
      #clock:hover,
      #pulseaudio:hover,
      #network:hover,
      #custom-notification:hover {
        background: alpha(@surface, ${toString t.glass});
        border-color: alpha(@accent, 0.6);
      }

      #workspaces {
        padding: 0 6px;
      }

      #workspaces button {
        color: @overlay;
        padding: 0 6px;
        margin: 4px 1px;
        border-radius: ${toString (t.radius - 4)}px;
        background: transparent;
        transition: all 200ms ease;
      }

      #workspaces button:hover {
        color: @text;
        background: alpha(@surface, 0.8);
        box-shadow: none;
      }

      #workspaces button.active {
        color: @accent;
      }

      #workspaces button.urgent {
        color: @red;
      }

      #window {
        color: @subtext;
      }

      window#waybar.empty #window {
        background: transparent;
        border-color: transparent;
      }

      #clock {
        color: @text;
        font-weight: bold;
      }

      #hardware {
        padding: 0 6px;
      }

      #cpu,
      #memory {
        padding: 0 8px;
      }

      #cpu {
        color: @blue;
      }

      #memory {
        color: @cyan;
      }

      #cpu.warning,
      #memory.warning,
      #battery.warning:not(.charging) {
        color: @yellow;
      }

      #cpu.critical,
      #memory.critical,
      #battery.critical:not(.charging) {
        color: @red;
      }

      #pulseaudio {
        color: @accent;
      }

      #pulseaudio.muted {
        color: @overlay;
      }

      #network {
        color: @green;
      }

      #network.disconnected {
        color: @red;
      }

      #battery {
        color: @green;
      }

      #battery.charging,
      #battery.plugged {
        color: @cyan;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      #custom-notification {
        color: @text;
        padding: 0 16px 0 14px;
      }

      #custom-notification.notification,
      #custom-notification.inhibited-notification {
        color: @accent;
      }

      #custom-notification.dnd-none,
      #custom-notification.dnd-notification,
      #custom-notification.dnd-inhibited-none,
      #custom-notification.dnd-inhibited-notification {
        color: @overlay;
      }
    '';
  };
}
