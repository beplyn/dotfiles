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

    areofyl-fetch.url = "github:areofyl/fetch";

    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    catppuccin.url = "github:catppuccin/nix";

    netspd.url = "github:TarunVishwakarma1/netspd";

    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      forgejo-cli,
      nixvim,
      areofyl-fetch,
      millennium,
      catppuccin,
      netspd,
      sops-nix,
      ...
    }:
    let
      username = "beplyn";
      email = "me@beplyn.dev";
      forgejoHost = "codeberg.org";
    in
    {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit
            inputs
            username
            email
            forgejoHost
            ;
        };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          { nixpkgs.overlays = [ millennium.overlays.default ]; }
          ./hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit
                inputs
                username
                email
                forgejoHost
                ;
            };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.sharedModules = [
              catppuccin.homeModules.catppuccin
              nixvim.homeModules.nixvim
              areofyl-fetch.homeManagerModules.default
              sops-nix.homeManagerModules.sops
            ];
            home-manager.users.${username} = {
              imports = [
                ./modules/home-manager/home.nix
              ];
              home.username = username;
              home.homeDirectory = "/home/${username}";
              home.stateVersion = "26.11";
            };
          }
        ];
      };
    };
}
