{
  programs.nixvim =
  {
    enable = true;
    defaultEditor = true;

    nixpkgs.config.allowUnfree = true;

    opts =
    {
      number = true;
      relativenumber = true;
      cursorline = true;
      signcolumn = "yes";
      splitbelow = true;
      splitright = true;
      scrolloff = 8;
      sidescrolloff = 8;
      updatetime = 250;
      timeoutlen = 400;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };
  };
}
