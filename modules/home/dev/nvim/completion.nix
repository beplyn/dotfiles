{ pkgs, ... }:

{
  programs.nixvim =
  {
    opts =
    {
      wildmenu = true;
      wildmode = "longest:full,full";
      wildoptions = [ "pum" ];
      completeopt =
      [
        "menu"
        "menuone"
        "noselect"
      ];
      pumheight = 8;
      pumblend = 0;
    };

    plugins.cmp =
    {
      enable = true;
      autoEnableSources = true;
      settings =
      {
        sources =
        [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
        # never preselect; <CR> only confirms a <Tab> pick
        preselect = "cmp.PreselectMode.None";
        completion.completeopt = "menu,menuone,noselect";
        mapping =
        {
          "<Down>" = "cmp.mapping.select_next_item()";
          "<Up>" = "cmp.mapping.select_prev_item()";
          # confirm selection, else newline
          "<CR>" = "cmp.mapping.confirm({ select = false })";
          "<C-y>" = "cmp.mapping.confirm({ select = true })";
          # <S-Tab> past the first item deselects
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
              else
                fallback()
              end
            end, { "i", "s" })
          '';
          "<S-Tab>" = ''
            cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
              else
                fallback()
              end
            end, { "i", "s" })
          '';
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins;
    [
      nvim-web-devicons
    ];
  };
}
