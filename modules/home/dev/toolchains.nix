{ pkgs, ... }:

{
  # compilers/interpreters for the langs the nvim LSPs cover
  home.packages = with pkgs;
  [
    # C / C++
    gcc
    gnumake
    # Haskell
    ghc
    cabal-install
    # Rust
    cargo
    rustc
    # Zig
    zig
    # Go
    go
    # C#
    dotnet-sdk_10
  ];
}
