{ headless, ... }:

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

  # rga drags in pandoc, poppler and ffmpeg
  programs.ripgrep-all.enable = !headless;
}
