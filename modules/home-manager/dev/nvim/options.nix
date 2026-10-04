{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # Permit Nixvim's internal nixpkgs evaluator to build unfree packages (copilot)
    nixpkgs.config.allowUnfree = true;

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };
  };
}
