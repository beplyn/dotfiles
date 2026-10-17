{ config, lib, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in

{
  stylix.targets.nixvim = {
    enable = true;
    transparentBackground.main = false;
  };

  programs.nixvim = {
    autoCmd = [
      {
        event = [
          "ColorScheme"
          "VimEnter"
        ];
        pattern = [ "*" ];
        callback = {
          __raw = builtins.replaceStrings
            [
              "@base00@"
              "@base01@"
              "@base04@"
              "@base05@"
              "@base0C@"
              "@base0D@"
              "@base0E@"
            ]
            [
              c.base00
              c.base01
              c.base04
              c.base05
              c.base0C
              c.base0D
              c.base0E
            ]
            (builtins.readFile ./lua/highlights.lua);
        };
      }
    ];

    extraFiles = {
      "logos".source = ./logos;
      "lua/random_logo.lua".source = ./lua/random_logo.lua;
      "lua/alpha.lua".source = ./lua/alpha.lua;
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
