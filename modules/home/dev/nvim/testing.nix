{
  programs.nixvim.plugins.neotest = {
    enable = true;
    adapters = {
      gtest.enable = true;
      haskell.enable = true;
      rust.enable = true;
      zig.enable = true;
    };
  };
}
