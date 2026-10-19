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
    highlightOverride = {
      "@comment".fg = c.base0C;
      "@comment".italic = true;
      "@keyword".fg = c.base0E;
      "@function".fg = c.base0D;
      "@function.builtin".fg = c.base0D;
      "@variable".fg = c.base05;
      "@variable.builtin".fg = c.base0E;
      "@variable.parameter".fg = c.base08;
      "@property".fg = c.base0C;
      "@type".fg = c.base0A;
      "@constant".fg = c.base09;
      "@number".fg = c.base09;
      "@string".fg = c.base0B;
      "@string.special".fg = c.base0C;
      "@string.special.path".fg = c.base0C;
      "@string.special.uri".fg = c.base0C;
      "@escape".fg = c.base0C;
      "@operator".fg = c.base0D;
      "@punctuation.delimiter".fg = c.base04;
      "@punctuation.bracket".fg = c.base04;
      "@punctuation.special".fg = c.base0E;
      "@embedded".fg = c.base0A;
    };

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
