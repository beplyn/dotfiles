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
        # Never start with an item selected (LSP servers can request this),
        # so <CR> only confirms something picked with <Tab>/<S-Tab>.
        preselect = "cmp.PreselectMode.None";
        completion.completeopt = "menu,menuone,noselect";
        mapping =
        {
          "<Down>" = "cmp.mapping.select_next_item()";
          "<Up>" = "cmp.mapping.select_prev_item()";
          # Confirms an explicitly selected item, otherwise inserts a newline.
          "<CR>" = "cmp.mapping.confirm({ select = false })";
          "<C-y>" = "cmp.mapping.confirm({ select = true })";
          # Cycling passes through an unselected state between the last and
          # first item, so <S-Tab> past the first item deselects again.
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
