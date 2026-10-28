{
  config,
  pkgs,
  ...
}:

let
  t = import ./theme.nix { inherit config; };
  c = config.lib.stylix.colors.withHashtag;

  # screenshot [area|output]
  # Saves to ~/Pictures/Screenshots, copies to the clipboard and raises a
  # notification whose actions open the shot in satty, an image viewer or
  # the folder.
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      wl-clipboard
      libnotify
      satty
      xdg-utils
      jq
    ];
    text = ''
      mode="''${1:-area}"
      dir="$HOME/Pictures/Screenshots"
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      mkdir -p "$dir"

      case "$mode" in
        area)
          geometry="$(slurp -d \
            -b '${c.base00}66' \
            -c '${c.base0E}ff' \
            -s '${c.base0E}22' \
            -B '${c.base00}00' \
            -w 2)" || exit 0
          grim -g "$geometry" "$file"
          ;;
        output)
          output="$(niri msg --json focused-output | jq -r '.name')"
          grim -o "$output" "$file"
          ;;
        *)
          echo "usage: screenshot [area|output]" >&2
          exit 1
          ;;
      esac

      wl-copy --type image/png < "$file"

      action="$(notify-send \
        --app-name=Screenshot \
        --icon="$file" \
        --hint="string:image-path:$file" \
        --action=edit=Edit \
        --action=open=Open \
        --action=folder=Folder \
        --wait \
        "Screenshot saved" \
        "$(basename "$file") · copied to clipboard")" || exit 0

      case "$action" in
        edit) satty --filename "$file" --output-filename "$file" ;;
        open) xdg-open "$file" ;;
        folder) xdg-open "$dir" ;;
      esac
    '';
  };
in
{
  home.packages = [ screenshot ];

  xdg.configFile."satty/config.toml".source = (pkgs.formats.toml { }).generate "satty-config" {
    general = {
      early-exit = true;
      initial-tool = "arrow";
      copy-command = "wl-copy";
      annotation-size-factor = 1.5;
      save-after-copy = true;
      default-hide-toolbars = false;
      corner-roundness = t.radius;
      actions-on-enter = [ "save-to-clipboard" ];
      actions-on-escape = [ "exit" ];
    };
    font.family = config.stylix.fonts.monospace.name;
    color-palette.palette = [
      c.base0E
      c.base08
      c.base09
      c.base0A
      c.base0B
      c.base0D
      c.base05
    ];
  };
}
