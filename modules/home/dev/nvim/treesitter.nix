{ config, ... }:

{
  programs.nixvim.plugins.treesitter =
  {
    enable = true;
    grammarPackages = config.programs.nixvim.plugins.treesitter.package.allGrammars;
    settings =
    {
      highlight.enable = true;
      indent.enable = true;
    };
  };

  programs.nixvim.plugins.treesitter-context =
  {
    enable = true;
    settings =
    {
      # off until <leader>tc
      enable = false;
      max_lines = 3;
      min_rows = 2;
      multiline_threshold = 1;
      trim_scope = "outer";
      mode = "cursor";
      winblend = 0;
    };
  };
}
