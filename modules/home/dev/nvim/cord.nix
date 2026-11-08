{
  # discord rich presence, equibop's arrpc takes it
  programs.nixvim.plugins.cord =
  {
    enable = true;
    settings =
    {
      display.theme = "atom";
      # nixpkgs puts the server in the store; fetching one there fails
      advanced.server.update = "none";
    };
  };
}
