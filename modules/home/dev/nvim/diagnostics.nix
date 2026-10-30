{
  # nvim 0.11+ hides virtual text by default; show messages inline
  programs.nixvim.diagnostic.settings =
  {
    virtual_text = true;
    severity_sort = true;
  };

  programs.nixvim.plugins.trouble =
  {
    enable = true;
    settings =
    {
      auto_close = true;
      auto_preview = true;
      focus = true;
      use_diagnostic_signs = true;
    };
  };
}
