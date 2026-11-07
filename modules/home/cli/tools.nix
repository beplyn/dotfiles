{ pkgs, ... }:

{
  home.packages = with pkgs;
  [
    _7zz
    # `ouch c dir out.tar.gz`; plain `tar czf` works too
    ouch
    pigz
    curl
    tree-sitter
    unzip
    zip
  ];
}
