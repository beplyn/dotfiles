{ config, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "builtin";
        source = "NixOS";
        height = 20;
        padding.right = 3;
        color = {
          "1" = c.base0D;
          "2" = c.base0C;
        };
      };

      display = {
        separator = " ";
      };

      modules = [
        {
          type = "host";
          key = "╭─󰌢";
          keyColor = c.base0D;
        }
        {
          type = "cpu";
          key = "├─󰻠";
          keyColor = c.base0C;
        }
        {
          type = "gpu";
          key = "├─󰍛";
          keyColor = c.base0B;
        }
        {
          type = "disk";
          key = "├─";
          keyColor = c.base0A;
        }
        {
          type = "memory";
          key = "╰─󰑭";
          keyColor = c.base09;
        }
        "break"
        {
          type = "shell";
          key = "╭─";
          keyColor = c.base0B;
        }
        {
          type = "terminal";
          key = "├─";
          keyColor = c.base0C;
        }
        {
          type = "terminalfont";
          key = "├─";
          keyColor = c.base0D;
        }
        {
          type = "lm";
          key = "├─󰧨";
          keyColor = c.base0E;
        }
        {
          type = "wm";
          key = "╰─";
          keyColor = c.base0F;
        }
        "break"
        {
          type = "title";
          key = "╭─";
          format = "{user-name}@{host-name}";
          keyColor = c.base0E;
        }
        {
          type = "os";
          key = "├─{icon}";
          keyColor = c.base0D;
        }
        {
          type = "kernel";
          key = "├─";
          keyColor = c.base0C;
        }
        {
          type = "packages";
          key = "├─󰏖";
          keyColor = c.base0B;
        }
        {
          type = "media";
          key = "├─󰝚";
          keyColor = c.base0A;
        }
        {
          type = "uptime";
          key = "╰─󰅐";
          keyColor = c.base09;
        }
        {
          type = "colors";
          symbol = "circle";
        }
      ];
    };
  };
}
