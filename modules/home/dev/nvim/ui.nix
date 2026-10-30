{
  config,
  lib,
  subst,
  ...
}:
let
  p = config.themes.palette;
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
      "@comment".fg = p.muted;
      "@comment".italic = true;
      "@punctuation.delimiter".fg = p.subtext;
      "@punctuation.bracket".fg = p.cyan;
      "@punctuation.special".fg = p.purple;

      # --- Identifiers ---
      "@variable".fg = p.foreground;
      "@variable.builtin".fg = p.purple;
      "@variable.builtin".bold = true;
      "@variable.parameter".fg = p.red;
      "@variable.member".fg = p.blue;
      "@property".fg = p.yellow;
      "@field".fg = p.yellow;

      # --- Keywords ---
      "@keyword".fg = p.purple;
      "@keyword".bold = true;
      "@operator".fg = p.purple;
      "@type".fg = p.yellow;
      "@function".fg = p.blue;
      "@function.builtin".fg = p.blue;
      "@function.builtin".bold = true;

      # --- Literals ---
      "@string".fg = p.green;
      "@string.special".fg = p.cyan;
      "@string.special.path".fg = p.cyan;
      "@string.special.uri".fg = p.cyan;
      "@escape".fg = p.red;
      "@boolean".fg = p.orange;
      "@boolean".bold = true;
      "@number".fg = p.orange;
      "@constant".fg = p.orange;
      "@embedded".fg = p.yellow;

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
        fg = p.muted;
      };
      FoldColumn.bg = transparent;
      EndOfBuffer.bg = transparent;
      WinSeparator =
      {
        bg = transparent;
        fg = p.surface;
      };

      # --- Treesitter context ---
      TreesitterContext.bg = transparent;
      TreesitterContextLineNumber =
      {
        bg = transparent;
        fg = p.subtext;
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
        fg = p.green;
      };
      GitSignsChangeNr =
      {
        bg = transparent;
        fg = p.blue;
      };
      GitSignsDeleteNr =
      {
        bg = transparent;
        fg = p.red;
      };
      SignColumn.bg = transparent;
      LineNr.bg = transparent;
      LineNrAbove.bg = transparent;
      LineNrBelow.bg = transparent;
      CursorLine.bg = transparent;
      CursorLineNr =
      {
        bg = transparent;
        fg = p.purple;
        bold = true;
      };
      CursorLineSign.bg = transparent;
      CursorLineFold.bg = transparent;
      TabLine.bg = transparent;
      TabLineFill.bg = transparent;
      TabLineSel =
      {
        bg = transparent;
        fg = p.foreground;
      };

      BufferLineDevIconNix.bg = transparent;
      BufferLineDevIconNixSelected.bg = transparent;
      BufferLineDevIconDefault.bg = transparent;
      BufferLineDevIconDefaultSelected.bg = transparent;
      DevIconNix =
      {
        bg = transparent;
        fg = p.blue;
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
          __raw = subst p (builtins.readFile ./lua/highlights.lua);
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
            fg = p.foreground;
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
            fg = p.foreground;
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
