{ ... }:

{
  sops.defaultSopsFile = ../../secrets.yaml;

  imports = [
    ./gtk.nix
    ./qt.nix
    ./gaming.nix
    ./dev/module.nix
    ./cli/module.nix
  ];
}
