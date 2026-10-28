{ osConfig, themeName, ... }:

let
  # nixd evaluates these to complete options. Point it at this flake and the
  # configuration the current machine was built from.
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
      };
      zls.enable = true;
      fish_lsp.enable = true;
      bashls.enable = true;
      csharp_ls.enable = true;
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
            # Includes programs.nixvim.* via the nixvim home module.
            home-manager.expr = "${nixos}.options.home-manager.users.type.getSubOptions [ ]";
          };
        };
      };
    };
  };
}
