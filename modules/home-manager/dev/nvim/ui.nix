{
  programs.nixvim = {
    extraFiles = {
      "logos".source = ./logos;
      "lua/random_logo.lua".source = ./lua/random_logo.lua;
      "lua/alpha.lua".source = ./lua/alpha.lua;
    };

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent = false;
        terminal_colors = true;
        styles = {
          comments = [ "italic" ];
          functions = [ "bold" ];
        };
        integrations = {
          lualine = true;
        };
      };
    };

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
