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
          "1" = "#179299";
          "2" = "#179299";
          "3" = "#179299";
          "4" = "#179299";
          "5" = "#179299";
          "6" = "#179299";
          "7" = "#179299";
          "8" = "#179299";
          "9" = "#179299";
        };
      };

      display = {
        separator = " ";
        color = {
          title = "#8839ef";
          keys = "";
          separator = "";
          output = "#9ca0b0";
        };
      };

      modules = [
        {
          type = "host";
          key = "╭─󰌢";
          keyColor = "#fe640b";
        }
        {
          type = "cpu";
          key = "├─󰻠";
          keyColor = "#fe640b";
        }
        {
          type = "gpu";
          key = "├─󰍛";
          keyColor = "#fe640b";
        }
        {
          type = "disk";
          key = "├─";
          keyColor = "#fe640b";
        }
        {
          type = "memory";
          key = "╰─󰑭";
          keyColor = "#fe640b";
        }
        "break"
        {
          type = "shell";
          key = "╭─";
          keyColor = "#df8e1d";
        }
        {
          type = "terminal";
          key = "├─";
          keyColor = "#df8e1d";
        }
        {
          type = "terminalfont";
          key = "├─";
          keyColor = "#df8e1d";
        }
        {
          type = "lm";
          key = "├─󰧨";
          keyColor = "#df8e1d";
        }
        {
          type = "wm";
          key = "╰─";
          keyColor = "#df8e1d";
        }
        "break"
        {
          type = "title";
          key = "╭─";
          format = "{user-name}@{host-name}";
          keyColor = "#179299";
        }
        {
          type = "os";
          key = "├─{icon}";
          keyColor = "#179299";
        }
        {
          type = "kernel";
          key = "├─";
          keyColor = "#179299";
        }
        {
          type = "packages";
          key = "├─󰏖";
          keyColor = "#179299";
        }
        {
          type = "media";
          key = "├─󰝚";
          keyColor = "#179299";
        }
        {
          type = "uptime";
          key = "╰─󰅐";
          keyColor = "#179299";
        }
      ];
    };
  };
}
