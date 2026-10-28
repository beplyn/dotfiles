{
  programs.ripgrep =
  {
    enable = true;
    arguments =
    [
      "--hidden"
      "--max-columns=150"
      "--max-columns-preview"
    ];
  };

  programs.ripgrep-all.enable = true;
}
