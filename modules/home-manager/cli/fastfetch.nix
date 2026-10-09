{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "builtin";
        source = "NixOS";
        height = 20;
        padding.right = 3;
      };

      display = {
        separator = " ";
      };

      modules = [
        {
          type = "host";
          key = "╭─󰌢";
        }
        {
          type = "cpu";
          key = "├─󰻠";
        }
        {
          type = "gpu";
          key = "├─󰍛";
        }
        {
          type = "disk";
          key = "├─";
        }
        {
          type = "memory";
          key = "╰─󰑭";
        }
        "break"
        {
          type = "shell";
          key = "╭─";
        }
        {
          type = "terminal";
          key = "├─";
        }
        {
          type = "terminalfont";
          key = "├─";
        }
        {
          type = "lm";
          key = "├─󰧨";
        }
        {
          type = "wm";
          key = "╰─";
        }
        "break"
        {
          type = "title";
          key = "╭─";
          format = "{user-name}@{host-name}";
        }
        {
          type = "os";
          key = "├─{icon}";
        }
        {
          type = "kernel";
          key = "├─";
        }
        {
          type = "packages";
          key = "├─󰏖";
        }
        {
          type = "media";
          key = "├─󰝚";
        }
        {
          type = "uptime";
          key = "╰─󰅐";
        }
      ];
    };
  };
}
