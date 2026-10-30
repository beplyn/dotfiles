{ config, ... }:

let
  p = config.themes.palette;
in
{
  programs.fastfetch =
  {
    enable = true;
    settings =
    {
      logo =
      {
        type = "builtin";
        source = "NixOS";
        height = 20;
        padding.right = 3;
        color =
        {
          "1" = p.blue;
          "2" = p.cyan;
        };
      };

      display =
      {
        separator = " ";
      };

      modules =
      [
        {
          type = "host";
          key = "╭─󰌢";
          keyColor = p.blue;
        }
        {
          type = "cpu";
          key = "├─󰻠";
          keyColor = p.cyan;
        }
        {
          type = "gpu";
          key = "├─󰍛";
          keyColor = p.green;
        }
        {
          type = "disk";
          key = "├─";
          keyColor = p.yellow;
        }
        {
          type = "memory";
          key = "╰─󰑭";
          keyColor = p.orange;
        }
        "break"
        {
          type = "shell";
          key = "╭─";
          keyColor = p.green;
        }
        {
          type = "terminal";
          key = "├─";
          keyColor = p.cyan;
        }
        {
          type = "terminalfont";
          key = "├─";
          keyColor = p.blue;
        }
        {
          type = "lm";
          key = "├─󰧨";
          keyColor = p.purple;
        }
        {
          type = "wm";
          key = "╰─";
          keyColor = p.brown;
        }
        "break"
        {
          type = "title";
          key = "╭─";
          format = "{user-name}@{host-name}";
          keyColor = p.purple;
        }
        {
          type = "os";
          key = "├─{icon}";
          keyColor = p.blue;
        }
        {
          type = "kernel";
          key = "├─";
          keyColor = p.cyan;
        }
        {
          type = "packages";
          key = "├─󰏖";
          keyColor = p.green;
        }
        {
          type = "media";
          key = "├─󰝚";
          keyColor = p.yellow;
        }
        {
          type = "uptime";
          key = "╰─󰅐";
          keyColor = p.orange;
        }
        "break"
        "break"
        {
          type = "colors";
          symbol = "circle";
        }
      ];
    };
  };
}
