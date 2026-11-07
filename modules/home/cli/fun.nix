{ pkgs, ... }:

# toys: `fortune | cowsay | lolcat`, `toilet -f future --gay hi`
{
  home.packages = with pkgs;
  [
    sl
    lolcat
    toilet
    figlet
    cowsay
    fortune
    cmatrix
    pipes-rs
    asciiquarium-transparent
    cbonsai
    nyancat
    genact
  ];

  # Stylix colours it; the bar visualiser keeps its own config (quickshell)
  programs.cava.enable = true;
  stylix.targets.cava.rainbow.enable = true;
}
