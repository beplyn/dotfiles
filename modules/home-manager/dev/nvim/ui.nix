{ config, lib, ... }:

{
  programs.nixvim = {
    extraFiles = {
      "logos".source = ./logos;
      "lua/random_logo.lua".source = ./lua/random_logo.lua;
      "lua/alpha.lua".source = ./lua/alpha.lua;
    };

    colorschemes.catppuccin.enable = config.themes.active == "catppuccin";
    colorschemes.catppuccin.settings = {
      transparent_background = true;
    };
    colorschemes.gruvbox.enable = config.themes.active == "gruvbox";
    colorschemes.nord.enable = config.themes.active == "nord";
    colorschemes.nord.settings = {
      disable_background = true;
    };

    autoCmd = [
      {
        event = "ColorScheme";
        pattern = "*";
        callback = {
          __raw = ''
            function()
              for _, group in ipairs({
                "Normal",
                "NormalNC",
                "NormalFloat",
                "FloatBorder",
                "SignColumn",
                "EndOfBuffer",
                "AlphaHeader",
                "AlphaButtons",
                "AlphaShortcut",
                "AlphaFooter",
                "DashboardRandomLogo",
              }) do
                vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
              end
            end
          '';
        };
      }
    ];

    plugins = {
      alpha = {
        enable = true;
        theme = "dashboard";
        luaConfig.content = builtins.readFile ./lua/alpha.lua;
      };

      transparent = {
        enable = true;
        settings = {
          extra_groups = [
            "NormalFloat"
            "FloatBorder"
            "AlphaHeader"
            "AlphaButtons"
            "AlphaShortcut"
            "AlphaFooter"
            "DashboardRandomLogo"
          ];
        };
      };

      lualine = {
        enable = true;
        settings = {
          options = {
            globalstatus = true;
            theme = "auto";
            component_separators = "";
            section_separators = "";
          };
        };
      };

      bufferline = {
        enable = true;
        settings.options = {
          mode = "buffers";
          diagnostics = "nvim_lsp";
          separator_style = "slant";
          show_buffer_close_icons = false;
          show_close_icon = false;
        };
      };

      web-devicons.enable = true;
    };
  };
}
