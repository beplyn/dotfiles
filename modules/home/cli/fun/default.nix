{ pkgs, ... }:

# toys: `fortune | cowsay | lolcat`, `toilet -f future --gay hi`, or `fun`
let
  toys = with pkgs;
  [
    sl
    lolcat
    toilet
    figlet
    cowsay
    ponysay
    fortune
    cmatrix
    pipes-rs
    asciiquarium-transparent
    cbonsai
    nyancat
    genact
  ];

  # rolls one of the toys above, alone or piped together
  fun = pkgs.writeShellApplication
  {
    name = "fun";
    runtimeInputs = toys ++ [ pkgs.coreutils pkgs.hostname ];
    text = builtins.readFile ./fun.sh;
  };
in
{
  home.packages = toys ++ [ fun ];

  # Stylix colours it; the bar visualiser keeps its own config (quickshell)
  programs.cava.enable = true;
  stylix.targets.cava.rainbow.enable = true;
}
