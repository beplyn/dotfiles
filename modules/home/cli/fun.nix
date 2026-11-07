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
}
