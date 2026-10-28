{ pkgs, ... }:

{
  home.packages = with pkgs;
  [
    _7zz
    curl
    tree-sitter
    unzip
    zip
  ];
}
