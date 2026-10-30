{
  config,
  lib,
  ...
}:
let
  c = config.lib.stylix.colors.withHashtag;
  transparent = lib.mkForce "NONE";
in
{
  stylix.targets.nixvim =
  {
    enable = true;
    transparentBackground.main = true;
    transparentBackground.numberLine = true;
  };

  programs.nixvim =
  {
    opts.termguicolors = true;
    highlightOverride =
    {
      # --- Comments ---
      "@comment".fg = c.base03;
      "@comment".italic = true;
      "@punctuation.delimiter".fg = c.base04;
      "@punctuation.bracket".fg = c.base0C;
      "@punctuation.special".fg = c.base0E;

      # --- Identifiers ---
      "@variable".fg = c.base05;
      "@variable.builtin".fg = c.base0E;
      "@variable.builtin".bold = true;
      "@variable.parameter".fg = c.base08;
      "@variable.member".fg = c.base0D;
      "@property".fg = c.base0A;
      "@field".fg = c.base0A;

      # --- Keywords ---
      "@keyword".fg = c.base0E;
      "@keyword".bold = true;
      "@operator".fg = c.base0E;
      "@type".fg = c.base0A;
      "@function".fg = c.base0D;
      "@function.builtin".fg = c.base0D;
      "@function.builtin".bold = true;

      # --- Literals ---
      "@string".fg = c.base0B;
      "@string.special".fg = c.base0C;
      "@string.special.path".fg = c.base0C;
      "@string.special.uri".fg = c.base0C;
      "@escape".fg = c.base08;
      "@boolean".fg = c.base09;
      "@boolean".bold = true;
      "@number".fg = c.base09;
      "@constant".fg = c.base09;
      "@embedded".fg = c.base0A;

      # --- Transparency ---
      Normal =
      {
        bg = transparent;
        ctermbg = transparent;
      };
      NormalNC =
      {
        bg = transparent;
        ctermbg = transparent;
      };
      NormalFloat =
      {
        bg = transparent;
        ctermbg = transparent;
      };
      FloatBorder =
      {
        bg = transparent;
        fg = c.base03;
      };
      FoldColumn.bg = transparent;
      EndOfBuffer.bg = transparent;
      WinSeparator =
      {
        bg = transparent;
        fg = c.base02;
      };

      # --- Treesitter context ---
      TreesitterContext.bg = transparent;
      TreesitterContextLineNumber =
      {
        bg = transparent;
        fg = c.base04;
      };
      TreesitterContextBottom =
      {
        underline = false;
        bg = transparent;
      };

      # transparent gutter, keep diff colours
      GitSignsAddNr =
      {
        bg = transparent;
        fg = c.base0B;
      };
      GitSignsChangeNr =
      {
        bg = transparent;
        fg = c.base0D;
      };
      GitSignsDeleteNr =
      {
        bg = transparent;
        fg = c.base08;
      };
      SignColumn.bg = transparent;
      LineNr.bg = transparent;
      LineNrAbove.bg = transparent;
      LineNrBelow.bg = transparent;
      CursorLine.bg = transparent;
      CursorLineNr =
      {
        bg = transparent;
        fg = c.base0E;
        bold = true;
      };
      CursorLineSign.bg = transparent;
      CursorLineFold.bg = transparent;
      TabLine.bg = transparent;
      TabLineFill.bg = transparent;
      TabLineSel =
      {
        bg = transparent;
        fg = c.base05;
      };

      BufferLineDevIconNix.bg = transparent;
      BufferLineDevIconNixSelected.bg = transparent;
      BufferLineDevIconDefault.bg = transparent;
      BufferLineDevIconDefaultSelected.bg = transparent;
      DevIconNix =
      {
        bg = transparent;
        fg = c.base0D;
      };
    };
    autoCmd =
    [
      {
        event =
        [
          "ColorScheme"
          "VimEnter"
        ];
        pattern = [ "*" ];
        callback =
        {
          __raw =
            builtins.replaceStrings
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

    extraFiles =
    {
      "logos".source = ./logos;
      "lua/random_logo.lua".source = ./lua/random_logo.lua;
      "lua/alpha.lua".source = ./lua/alpha.lua;
    };

    plugins =
    {
      alpha =
      {
        enable = true;
        theme = "dashboard";
        luaConfig.content = builtins.readFile ./lua/alpha.lua;
      };

      lualine =
      {
        enable = true;
        settings =
        {
          options =
          {
            globalstatus = true;
            theme = "auto";
            component_separators = "";
            section_separators = "";
          };
        };
      };

      bufferline =
      {
        enable = true;
        settings.options =
        {
          mode = "buffers";
          diagnostics = "nvim_lsp";
          indicator.style = "none";
          separator_style = "thin";
          show_buffer_close_icons = false;
          show_close_icon = false;
        };
        settings.highlights =
        {
          fill.bg = "NONE";
          background.bg = "NONE";
          tab.bg = "NONE";
          tab_selected =
          {
            bg = "NONE";
            fg = c.base05;
          };
          separator_selected =
          {
            fg = "NONE";
            bg = "NONE";
          };
          separator =
          {
            fg = "NONE";
            bg = "NONE";
          };
          buffer_selected =
          {
            bg = "NONE";
            fg = c.base05;
            bold = true;
          };
          buffer_visible.bg = "NONE";
          indicator_selected =
          {
            fg = "NONE";
            bg = "NONE";
          };
          indicator_visible =
          {
            fg = "NONE";
            bg = "NONE";
          };
          modified_selected.bg = "NONE";
        };
      };

      web-devicons.enable = true;
    };
  };
}
