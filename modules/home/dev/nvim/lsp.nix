{
  pkgs,
  osConfig,
  themeName,
  headless,
  ...
}:

let
  # nixd: options from this flake and host
  flake = ''(builtins.getFlake "/etc/nixos")'';
  nixos = ''${flake}.nixosConfigurations."${osConfig.networking.hostName}-${themeName}"'';
  # compiled langs only where their toolchains are (toolchains.nix)
  full = !headless;
in
{
  programs.nixvim.plugins.lsp =
  {
    enable = true;
    servers =
    {
      clangd.enable = full;
      hls =
      {
        enable = full;
        installGhc = true;
      };
      rust_analyzer =
      {
        enable = full;
        installCargo = true;
        installRustc = true;
        installRustfmt = true;
        extraOptions.before_init.__raw = builtins.readFile ./lua/rust-detached.lua;
      };
      zls.enable = full;
      fish_lsp.enable = true;
      bashls.enable = true;
      csharp_ls =
      {
        enable = full;
        # nixvim's own pin is built on an older glibc than our dotnet-sdk,
        # whose runtime it loads from PATH and then dies on
        package = pkgs.csharp-ls;
      };
      gopls.enable = full;
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
