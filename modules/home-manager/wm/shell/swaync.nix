{
  config,
  ...
}:

let
  t = import ./theme.nix { inherit config; };
  c = config.lib.stylix.colors;
  rgb = base: "${c."${base}-rgb-r"}, ${c."${base}-rgb-g"}, ${c."${base}-rgb-b"}";
  r = toString t.radius;
in
{
  stylix.targets.swaync.enable = false;

  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "user";

      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 10;
      control-center-margin-left = 0;
      control-center-width = 420;

      notification-window-width = 400;
      notification-icon-size = 48;
      notification-body-image-height = 120;
      notification-body-image-width = 200;
      notification-2fa-action = true;
      notification-inline-replies = true;

      timeout = 6;
      timeout-low = 3;
      timeout-critical = 0;
      fit-to-screen = true;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = true;
      hide-on-action = true;
      relative-timestamps = true;

      widgets = [
        "title"
        "dnd"
        "volume"
        "backlight"
        "mpris"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "󰎟  clear";
        };
        dnd.text = "Do not disturb";
        volume = {
          label = "󰕾";
          show-per-app = false;
        };
        backlight = {
          label = "󰃟";
          subsystem = "backlight";
        };
        mpris = {
          image-size = 64;
          blur = true;
        };
      };
    };

    # Build on swaync's own stylesheet so new upstream widgets stay styled,
    # then repaint its variables and surfaces from Stylix.
    style = ''
      @import url("file://${config.services.swaync.package}/etc/xdg/swaync/style.css");

      ${t.css}

      :root {
        --cc-bg: alpha(@base, ${toString t.glass});
        --noti-border-color: alpha(@overlay, 0.6);
        --noti-bg: ${rgb "base00"};
        --noti-bg-alpha: ${toString t.glass};
        --noti-bg-darker: @mantle;
        --noti-bg-hover: @surface;
        --noti-bg-focus: alpha(@surface, 0.8);
        --noti-close-bg: @surface;
        --noti-close-bg-hover: @overlay;
        --text-color: @text;
        --text-color-disabled: @overlay;
        --bg-selected: @accent;
        --border-radius: ${r}px;
        --notification-icon-size: 48px;
        --notification-shadow: 0 4px 16px alpha(@base, 0.5);
        --font-size-body: ${toString (t.popupFontSize + 1)}pt;
        --font-size-summary: ${toString (t.popupFontSize + 2)}pt;
        --mpris-album-art-overlay: alpha(@base, 0.6);
        --mpris-button-hover: alpha(@surface, 0.8);
      }

      * {
        font-family: ${t.font};
      }

      /* --- cards ------------------------------------------------------ */

      .notification-row .notification-background .notification {
        border: 1px solid alpha(@overlay, 0.6);
        border-radius: ${r}px;
        transition: border-color 200ms ease;
      }

      .notification-row .notification-background .notification:hover {
        border-color: alpha(@accent, 0.6);
      }

      .notification-row .notification-background .notification.critical {
        border-color: @red;
      }

      .notification-row .notification-background .notification.low {
        opacity: 0.85;
      }

      .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .summary {
        color: @bright;
        font-weight: bold;
      }

      .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .body {
        color: @subtext;
      }

      .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .time {
        color: @overlay;
      }

      .notification-row .notification-background .notification .notification-default-action .notification-content progressbar progress {
        background: @accent;
      }

      .notification-row .notification-background .notification .notification-action > button {
        background: alpha(@surface, 0.6);
        color: @text;
        border-radius: ${toString (t.radius - 4)}px;
        transition: all 150ms ease;
      }

      .notification-row .notification-background .notification .notification-action > button:hover {
        background: alpha(@accent, 0.25);
        color: @accent;
      }

      .close-button {
        background: @surface;
        color: @text;
        border-radius: 999px;
      }

      .close-button:hover {
        background: @red;
        color: @base;
      }

      /* --- control center --------------------------------------------- */

      .control-center {
        border: 1px solid alpha(@overlay, 0.6);
        border-radius: ${r}px;
        padding: 6px;
      }

      .control-center .control-center-list-placeholder {
        color: @overlay;
      }

      .widget {
        margin: 6px 8px;
      }

      .widget-title > label {
        color: @text;
        font-size: ${toString (t.popupFontSize + 4)}pt;
        font-weight: bold;
      }

      .widget-title > button {
        background: alpha(@surface, 0.8);
        color: @text;
        border: 1px solid alpha(@overlay, 0.6);
        border-radius: ${r}px;
        padding: 4px 12px;
      }

      .widget-title > button:hover {
        background: alpha(@red, 0.2);
        border-color: @red;
        color: @red;
      }

      .widget-dnd {
        background: alpha(@surface, 0.5);
        border-radius: ${r}px;
        padding: 8px 12px;
      }

      .widget-dnd label {
        color: @text;
      }

      .widget-dnd switch {
        background: @surface;
        border-radius: 999px;
      }

      .widget-dnd switch:checked {
        background: @accent;
      }

      .widget-dnd switch slider {
        background: @text;
        border-radius: 999px;
      }

      .widget-volume,
      .widget-backlight {
        background: alpha(@surface, 0.5);
        border-radius: ${r}px;
        padding: 6px 12px;
      }

      .widget-slider label {
        color: @accent;
        font-size: ${toString (t.popupFontSize + 4)}pt;
      }

      .widget-volume scale trough,
      .widget-backlight scale trough {
        background: @surface;
        border-radius: 999px;
        min-height: 6px;
      }

      .widget-volume scale highlight,
      .widget-backlight scale highlight {
        background: @accent;
        border-radius: 999px;
      }

      .widget-volume scale slider,
      .widget-backlight scale slider {
        background: @text;
        border-radius: 999px;
        min-width: 14px;
        min-height: 14px;
      }

      .widget-mpris .widget-mpris-player {
        border-radius: ${r}px;
      }

      .widget-mpris .widget-mpris-player .mpris-overlay .widget-mpris-title {
        color: @bright;
        font-weight: bold;
      }

      .widget-mpris .widget-mpris-player .mpris-overlay .widget-mpris-subtitle {
        color: @subtext;
      }
    '';
  };
}
