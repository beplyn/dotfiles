{ config, lib, ... }:

{
  programs.nixvim = {
    extraFiles = {
      "logos".source = ./logos;
      "lua/random_logo.lua".source = ./lua/random_logo.lua;
      "lua/alpha.lua".source = ./lua/alpha.lua;
    };

    colorschemes.gruvbox.enable = config.themes.active == "gruvbox";
    colorschemes.nord.enable = config.themes.active == "nord";

    plugins = {
      alpha = {
        enable = true;
        theme = "dashboard";
        luaConfig.content = builtins.readFile ./lua/alpha.lua;
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
