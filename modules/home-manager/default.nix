{ ... }:

{
  imports = [
    ./graphical/module.nix
    ./dev/module.nix
    ./cli/module.nix
    ./wm/module.nix
    ../theme
  ];
}
