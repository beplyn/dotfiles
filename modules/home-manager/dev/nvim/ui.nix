{ config, lib, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
  logoColors = ''
    {
      "${c.base08}",
      "${c.base09}",
      "${c.base0A}",
      "${c.base0B}",
      "${c.base0C}",
      "${c.base0D}",
    }
  '';
in

{
  stylix.targets.nixvim = {
    enable = true;
    transparentBackground.main = true;
  };

  programs.nixvim = {
    extraFiles = {
      "logos".source = ./logos;
      "lua/random_logo.lua".text = ''
        local M = {}

        local theme_accents = ${logoColors}

        math.randomseed(os.time())

        function M.get_header()
          local logo_pattern = vim.fn.stdpath("config") .. "/logos/*.ascii"
          local logos = vim.fn.glob(logo_pattern, false, true)

          if #logos == 0 then
            error("No ASCII logos found in " .. vim.fn.fnamemodify(logo_pattern, ":h"))
          end

          local logo = logos[math.random(#logos)]
          local lines = vim.fn.readfile(logo)

          if #lines == 0 then
            error("ASCII logo is empty: " .. logo)
          end

          return lines
        end

        function M.get_accent_color()
          return theme_accents[math.random(#theme_accents)]
        end

        return M
      '';
      "lua/alpha.lua".source = ./lua/alpha.lua;
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
        enable = false;
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
