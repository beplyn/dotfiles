{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  stylixColors = config.lib.stylix.colors;

  # Converts 6-char hex to "R;G;B"
  toRgb =
    color:
    lib.concatStringsSep ";" (
      builtins.map (part: toString (lib.fromHexString part))
      [
        (builtins.substring 0 2 color)
        (builtins.substring 2 2 color)
        (builtins.substring 4 2 color)
      ]
    );

  ansi = color: "\\x1b[38;2;${toRgb color}m";
  reset = "\\x1b[0m";
  coloredKey = color: glyph: "${ansi color}${glyph}${reset}";

  system = pkgs.stdenv.hostPlatform.system;
  upstreamFetch = inputs.areofyl-fetch.packages.${system}.default;

  patchedFetch = upstreamFetch.overrideAttrs (oldAttrs:
  {
    postPatch = (oldAttrs.postPatch or "") + ''
      # 1. Strip the trailing colon and forced magenta escape from all labels
      # "%.0s" consumes label_color (prints 0 chars), followed by label and value with a clean 2-space gap
      sed -i 's/"\\033\[1;%sm%s\\033\[0m: %s"/"%.0s%s  %s"/g' fetch.c

      # 2. Suppress the default top title & separator
      substituteInPlace fetch.c \
        --replace 'static void gather_title(void) {' \
                  'static void gather_title(void) { return;'

      # 3. Inject "╭─ user@host" into Block 3 right above OS
      substituteInPlace fetch.c \
        --replace 'add_info("OS", "%s %s", pretty, u.machine);' \
                  'char u_n[64] = ""; char *l = getlogin(); if (l) strncpy(u_n, l, 63); else { char *e = getenv("USER"); if (e) strncpy(u_n, e, 63); } char h_n[64] = ""; gethostname(h_n, sizeof(h_n)); add_info("${coloredKey stylixColors.base0E "╭─"}", "%s@%s", u_n, h_n); add_info("OS", "%s %s", pretty, u.machine);'

      # 4. Patch Disk to show clean tree bracket without "Disk (/)" text
      substituteInPlace fetch.c \
        --replace 'snprintf(label, sizeof(label), "Disk (%s)", path);' \
                  'snprintf(label, sizeof(label), "%s", "${coloredKey stylixColors.base0A "├─"}");'

      # 5. Substitute add_info labels with colored Nerd Font tree brackets
      substituteInPlace fetch.c \
        --replace 'add_info("Host"'      'add_info("${coloredKey stylixColors.base0D "╭─󰌢"}"' \
        --replace 'add_info("CPU"'       'add_info("${coloredKey stylixColors.base0C "├─󰻠"}"' \
        --replace 'add_info("GPU"'       'add_info("${coloredKey stylixColors.base0B "├─󰍛"}"' \
        --replace 'add_info("Memory"'    'add_info("${coloredKey stylixColors.base09 "╰─󰑭"}"' \
        --replace 'add_info("Shell"'     'add_info("${coloredKey stylixColors.base0B "╭─"}"' \
        --replace 'add_info("Terminal"'  'add_info("${coloredKey stylixColors.base0C "├─"}"' \
        --replace 'add_info("WM"'        'add_info("${coloredKey stylixColors.base0F "╰─"}"' \
        --replace 'add_info("OS"'        'add_info("${coloredKey stylixColors.base0D "├─"}"' \
        --replace 'add_info("Kernel"'    'add_info("${coloredKey stylixColors.base0C "├─"}"' \
        --replace 'add_info("Packages"'  'add_info("${coloredKey stylixColors.base0B "├─󰏖"}"' \
        --replace 'add_info("Uptime"'    'add_info("${coloredKey stylixColors.base09 "╰─󰅐"}"'
    '';
  });
in
{
  programs.fetch.enable = lib.mkForce false;
  home.packages = [ patchedFetch ];

  xdg.configFile."fetch/config".text = builtins.readFile ./fetch.conf;

  home.file.".config/fetch/logo.txt".text = builtins.readFile ./fetch-logo.txt;
}
