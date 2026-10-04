{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    forgejo-cli = {
      url = "git+https://codeberg.org/forgejo-contrib/forgejo-cli.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      forgejo-cli,
      nixvim,
      ...
    }:
    {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.sharedModules = [
              nixvim.homeModules.nixvim
            ];
            home-manager.users.root = {
              imports = [
                ./modules/home-manager/home.nix
              ];
              home.username = "root";
              home.stateVersion = "26.11";
            };
            home-manager.users.beplyn = {
              imports = [
                ./modules/home-manager/home.nix
              ];
              home.username = "beplyn";
              home.homeDirectory = "/home/beplyn";
              home.stateVersion = "26.11";
            };
          }
        ];
      };
    };
}
