{ pkgs, username, ... }:

{
  home.packages = with pkgs;
  [
    _7zz
    # `ouch c dir out.tar.gz`; plain `tar czf` works too
    ouch
    pigz
    curl
    # `nom build`, or `nixos-rebuild ... |& nom`
    nix-output-monitor
    hyperfine
    tokei
    license-generator
    tree-sitter
    unzip
    zip
  ];

  # `license MIT` writes ./LICENSE; `license-generator -l` lists the rest
  programs.fish.shellAbbrs.license = "license-generator --author ${username}";
}
