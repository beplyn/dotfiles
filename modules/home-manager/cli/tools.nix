{ pkgs, ... }:

{
  home.packages = with pkgs; [
    curl
    tree-sitter
  ];
}
