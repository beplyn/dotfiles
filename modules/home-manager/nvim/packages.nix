{ pkgs, ... }:

{
  programs.nixvim.extraPackages = with pkgs; [
    nixfmt-rfc-style
    nixfmt
  ];
}
