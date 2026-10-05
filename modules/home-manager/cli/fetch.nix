{ ... }:

{
  programs.fetch = {
    enable = true;
    info = [
      "host"
      "cpu"
      "gpu"
      "disk"
      "memory"
      "shell"
      "terminal"
      "font"
      "display"
      "wm"
      "os"
      "kernel"
      "packages"
      "uptime"
    ];
    labelColor = "yellow";
    separator = " ";
    height = 20;
  };
}
