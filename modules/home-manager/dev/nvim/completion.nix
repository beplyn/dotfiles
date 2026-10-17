{ pkgs, ... }:

{
  programs.nixvim = {
    opts = {
      wildmenu = true;
      wildmode = "longest:full,full";
      wildoptions = [ "pum" ];
      pumheight = 8;
      pumblend = 0;
    };

    plugins.cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
        mapping = {
          "<Down>" = "cmp.mapping.select_next_item()";
          "<Up>" = "cmp.mapping.select_prev_item()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
    ];
  };
}
