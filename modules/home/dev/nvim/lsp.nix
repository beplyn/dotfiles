{ pkgs, osConfig, themeName, ... }:

let
  # nixd: options from this flake and host
  flake = ''(builtins.getFlake "/etc/nixos")'';
  nixos = ''${flake}.nixosConfigurations."${osConfig.networking.hostName}-${themeName}"'';
in
{
  programs.nixvim.plugins.lsp =
  {
    enable = true;
    servers =
    {
      clangd.enable = true;
      hls =
      {
        enable = true;
        installGhc = true;
      };
      rust_analyzer =
      {
        enable = true;
        installCargo = true;
        installRustc = true;
        installRustfmt = true;
        extraOptions.before_init.__raw = builtins.readFile ./lua/rust-detached.lua;
      };
      zls.enable = true;
      fish_lsp.enable = true;
      bashls.enable = true;
      csharp_ls =
      {
        enable = true;
        # nixvim's own pin is built on an older glibc than our dotnet-sdk,
        # whose runtime it loads from PATH and then dies on
        package = pkgs.csharp-ls;
      };
      gopls.enable = true;
      marksman.enable = true;
      nixd =
      {
        enable = true;
        settings =
        {
          nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
          options =
          {
            nixos.expr = "${nixos}.options";
            # includes programs.nixvim.*
            home-manager.expr = "${nixos}.options.home-manager.users.type.getSubOptions [ ]";
          };
        };
      };
    };
  };
}
