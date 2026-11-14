{
  lib,
  pkgs,
  username,
  headless,
  ...
}:

{
  home.packages = with pkgs;
  [
    curl
    # `nom build`, or `nixos-rebuild ... |& nom`
    nix-output-monitor
    unzip
    zip
  ]
  ++ lib.optionals (!headless)
  [
    _7zz
    # `ouch c dir out.tar.gz`; plain `tar czf` works too
    ouch
    pigz
    hyperfine
    tokei
    license-generator
    tree-sitter
  ];

  # `license MIT` writes ./LICENSE; `license-generator -l` lists the rest
  programs.fish.shellAbbrs = lib.mkIf (!headless)
  {
    license = "license-generator --author ${username}";
  };
}
