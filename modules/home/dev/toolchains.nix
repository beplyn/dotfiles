{ pkgs, ... }:

{
  # compilers/interpreters for the langs the nvim LSPs cover
  home.packages = with pkgs;
  [
    # C / C++
    gcc
    gnumake
    cmake
    ninja
    gdb
    # clangd, clang-format, clang-tidy on PATH (not just inside nvim)
    clang-tools
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
