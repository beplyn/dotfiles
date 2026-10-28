{
  config,
  ...
}:

let
  t = config.themes.shell;
  r = toString t.radius;
in
{
  # Elephant is walker's backend: it indexes apps, runs commands and keeps
  # the clipboard history that `walker -m clipboard` shows.
  services.elephant = {
    enable = true;
  };

  services.walker = {
    enable = true;
    systemd.enable = true;

    settings = {
      close_when_open = true;
      force_keyboard_focus = true;
      selection_wrap = true;
      click_to_close = true;

      placeholders = {
        default = {
          input = "Search";
          list = "Nothing found";
        };
        clipboard = {
          input = "Clipboard";
          list = "Clipboard is empty";
        };
      };

      providers = {
        default = [
          "desktopapplications"
          "calc"
          "runner"
          "websearch"
        ];
        empty = [ "desktopapplications" ];
        max_results = 50;
        clipboard.time_format = "relative";
      };
    };

    theme = {
      name = "stylix";
      style = ''
        ${t.css}

        * {
          all: unset;
          font-family: ${t.font};
          font-size: ${toString (t.popupFontSize + 2)}pt;
        }

        .normal-icons {
          -gtk-icon-size: 18px;
        }

        .large-icons {
          -gtk-icon-size: 32px;
        }

        scrollbar {
          opacity: 0;
        }

        popover {
          background: alpha(@base, 0.95);
          border: 1px solid alpha(@accent, 0.4);
          border-radius: ${r}px;
          padding: 8px;
          color: @text;
        }

        .box-wrapper {
          background: alpha(@base, ${toString t.glass});
          border: 1px solid alpha(@overlay, 0.6);
          border-radius: ${toString (t.radius + 6)}px;
          padding: 16px;
          box-shadow: 0 12px 32px alpha(@base, 0.6);
        }

        .search-container {
          background: alpha(@surface, 0.6);
          border: 1px solid transparent;
          border-radius: ${r}px;
          transition: border-color 200ms ease;
        }

        .search-container:focus-within {
          border-color: alpha(@accent, 0.7);
        }

        .input {
          padding: 12px 16px;
          color: @text;
          caret-color: @accent;
        }

        .input placeholder {
          color: @overlay;
        }

        .input selection {
          background: alpha(@accent, 0.35);
        }

        .content-container {
          margin-top: 10px;
        }

        .list {
          color: @text;
        }

        .item-box {
          padding: 8px 12px;
          border-radius: ${r}px;
          border: 1px solid transparent;
          transition: all 150ms ease;
        }

        child:hover .item-box,
        row:hover .item-box {
          background: alpha(@surface, 0.4);
        }

        child:selected .item-box,
        row:selected .item-box {
          background: alpha(@accent, 0.15);
          border-color: alpha(@accent, 0.5);
        }

        child:selected .item-text,
        row:selected .item-text {
          color: @accent;
        }

        .item-text-box {
          margin-left: 10px;
        }

        .item-subtext {
          font-size: ${toString t.popupFontSize}pt;
          color: @subtext;
          opacity: 0.8;
        }

        .item-quick-activation {
          background: alpha(@surface, 0.8);
          color: @subtext;
          border-radius: ${toString (t.radius - 6)}px;
          padding: 2px 8px;
          margin-left: 8px;
        }

        .item-image-text {
          font-size: 28px;
        }

        .placeholder,
        .elephant-hint {
          color: @overlay;
          padding: 16px;
        }

        .preview {
          background: alpha(@mantle, 0.8);
          border: 1px solid alpha(@overlay, 0.5);
          border-radius: ${r}px;
          padding: 10px;
          margin-left: 10px;
          color: @text;
        }

        .preview .large-icons {
          -gtk-icon-size: 64px;
        }

        .calc .item-text {
          font-size: 22pt;
          color: @green;
        }

        .symbols .item-image {
          font-size: 24px;
        }

        /* clipboard entries: show the timestamp quieter than the content */
        .clipboard .item-text {
          font-family: ${t.font};
        }

        .clipboard .item-subtext {
          color: @overlay;
        }

        .keybinds {
          margin-top: 10px;
          padding-top: 10px;
          border-top: 1px solid alpha(@overlay, 0.5);
          font-size: ${toString t.popupFontSize}pt;
          color: @subtext;
        }

        .keybind-button {
          opacity: 0.6;
        }

        .keybind-button:hover {
          opacity: 1;
        }

        .keybind-bind {
          text-transform: lowercase;
          color: @overlay;
        }

        .keybind-label {
          padding: 2px 6px;
          border-radius: 6px;
          border: 1px solid alpha(@overlay, 0.8);
        }

        .error {
          padding: 10px;
          border-radius: ${r}px;
          background: alpha(@red, 0.2);
          color: @red;
        }

        :not(.calc).current {
          font-style: italic;
        }
      '';
    };
  };
}
