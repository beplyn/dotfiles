{
  config,
  lib,
  pkgs,
  ...
}:

# toys: `fortune | cowsay | lolcat`, `toilet -f future --gay hi`, or `fun`
let
  # cowsay and cowthink roll a random cow every time
  cowsay = pkgs.symlinkJoin
  {
    name = "cowsay-random";
    paths = [ pkgs.cowsay ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for b in cowsay cowthink; do
        wrapProgram "$out/bin/$b" --add-flags -r
      done
    '';
  };

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
    lavat
    tty-clock
    terminal-parrot
    globe-cli
    neo
    boxes
    dotacat
    gti
    krabby
    cfonts
    bb
  ];

  # interactive, so `fun` leaves them out
  games = with pkgs;
  [
    bastet
    nsnake
    moon-buggy
    ninvaders
    _2048-in-terminal
    nudoku
    tty-solitaire
    ttyper
  ];

  p = config.themes.palette;
  hex = lib.removePrefix "#";

  # rolls one of the toys above, alone or piped together
  fun = pkgs.writeShellApplication
  {
    name = "fun";
    runtimeInputs = toys ++ [ pkgs.coreutils ];
    # lavat and cfonts paint in the scheme
    runtimeEnv =
    {
      FUN_ACCENT = hex p.accent;
      FUN_ACCENT2 = hex p.blue;
    };
    text = builtins.readFile ./fun.sh;
  };
in
{
  home.packages = toys ++ games ++ [ fun ];

  # Stylix colours it; the bar visualiser keeps its own config (quickshell)
  programs.cava.enable = true;
  stylix.targets.cava.rainbow.enable = true;
}
