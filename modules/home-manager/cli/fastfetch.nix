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
          title = "#179299";
          keys = "#179299";
          separator = "#179299";
          output = "#179299";
        };
      };

      modules = [
        {
          type = "host";
          key = "╭─󰌢";
          keyColor = "#179299";
        }
        {
          type = "cpu";
          key = "├─󰻠";
          keyColor = "#179299";
        }
        {
          type = "gpu";
          key = "├─󰍛";
          keyColor = "#179299";
        }
        {
          type = "disk";
          key = "├─";
          keyColor = "#179299";
        }
        {
          type = "memory";
          key = "╰─󰑭";
          keyColor = "#179299";
        }
        "break"
        {
          type = "shell";
          key = "╭─";
          keyColor = "#179299";
        }
        {
          type = "terminal";
          key = "├─";
          keyColor = "#179299";
        }
        {
          type = "terminalfont";
          key = "├─";
          keyColor = "#179299";
        }
        {
          type = "lm";
          key = "├─󰧨";
          keyColor = "#179299";
        }
        {
          type = "wm";
          key = "╰─";
          keyColor = "#179299";
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
