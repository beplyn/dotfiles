{
  programs.nixvim.plugins =
  {
    nvim-autopairs =
    {
      enable = true;
      settings =
      {
        check_ts = true;
        map_cr = true;
        map_c_h = true;
        map_c_w = true;
      };
    };

    comment.enable = true;
    indent-blankline =
    {
      enable = true;
      settings =
      {
        indent.char = "│";
        scope.enabled = true;
      };
    };
  };
}
