{
  programs.nixvim = {
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
      };
    };

    plugins = {
      lualine = {
        enable = true;
        settings = {
          options = {
            globalstatus = true;
            theme = "catppuccin";
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
