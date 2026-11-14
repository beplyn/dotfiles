{
  programs.nixvim.plugins.neotest =
  {
    enable = true;
    adapters =
    {
      gtest.enable = true;
      haskell.enable = true;
      rust.enable = true;
      zig.enable = true;
    };
  };

  programs.nixvim.keymaps =
  [
    {
      mode = "n";
      key = "<leader>tt";
      action = "<cmd>Neotest summary toggle<cr>";
      options.desc = "Test summary";
    }
    {
      mode = "n";
      key = "<leader>tr";
      action = "<cmd>Neotest run<cr>";
      options.desc = "Run nearest test";
    }
    {
      mode = "n";
      key = "<leader>td";
      action = "<cmd>Neotest run focused<cr>";
      options.desc = "Run focused test file";
    }
  ];
}
