{ config, ... }:

let
  p = config.themes.palette;
in
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      opener = {
        edit = [
          {
            run = "nvim %s";
            block = true;
            for = "unix";
          }
        ];
      };
      open = {
        prepend_rules = [
          {
            url = "*.nix";
            use = "edit";
          }
          {
            url = "*.lua";
            use = "edit";
          }
          {
            url = "*.sh";
            use = "edit";
          }
          {
            url = "*.toml";
            use = "edit";
          }
          {
            url = "*.yaml";
            use = "edit";
          }
          {
            url = "*.yml";
            use = "edit";
          }
          {
            url = "*.json";
            use = "edit";
          }
          {
            url = "*.md";
            use = "edit";
          }
          {
            mime = "text/*";
            use = "edit";
          }
          {
            mime = "application/x-subrip";
            use = "edit";
          }
        ];
      };
      theme = {
        mgr = {
          cwd = {
            fg = p.accent;
          };
          hovered = {
            fg = p.background;
            bg = p.accent;
          };
          preview_hovered = {
            underline = true;
          };
          find_keyword = {
            fg = p.warning;
            italic = true;
          };
          find_position = {
            fg = p.error;
            italic = true;
          };
          marker_copied = {
            fg = p.success;
            bg = p.success;
          };
          marker_cut = {
            fg = p.error;
            bg = p.error;
          };
          marker_marked = {
            fg = p.warning;
            bg = p.warning;
          };
          marker_selected = {
            fg = p.accent;
            bg = p.accent;
          };
          tab_active = {
            fg = p.background;
            bg = p.accent;
          };
          tab_inactive = {
            fg = p.foreground;
            bg = p.surface;
          };
          border_style = {
            fg = p.muted;
          };
        };

        mode = {
          normal_main = {
            fg = p.background;
            bg = p.accent;
            bold = true;
          };
          select_main = {
            fg = p.background;
            bg = p.success;
            bold = true;
          };
          unset_main = {
            fg = p.background;
            bg = p.error;
            bold = true;
          };
        };

        status = {
          overall = {
            fg = p.foreground;
            bg = p.surface;
          };
        };

        which = {
          mask = {
            bg = p.background;
          };
          cand = {
            fg = p.blue;
          };
          rest = {
            fg = p.muted;
          };
          desc = {
            fg = p.accent;
          };
          separator = "  ";
        };

        confirm = {
          border = {
            fg = p.accent;
          };
          title = {
            fg = p.accent;
          };
          body = {
            fg = p.foreground;
          };
          list = {
            fg = p.foreground;
          };
          btn_yes = {
            fg = p.background;
            bg = p.success;
          };
          btn_no = {
            fg = p.background;
            bg = p.error;
          };
        };
      };
    };
  };
}
