{
  programs.nixvim =
  {
    plugins =
    {
      telescope =
      {
        enable = true;
        enabledExtensions = [ "fzf" ];
        extensions.fzf-native.enable = true;
      };

      neo-tree.enable = true;
      which-key.enable = true;
    };
  };
}
