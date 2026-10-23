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

    netspd.url = "github:TarunVishwakarma1/netspd";

    sops-nix.url = "github:Mic92/sops-nix";

    ly = {
      url = "github:fairyglade/ly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";
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
      netspd,
      sops-nix,
      ly, niri
      stylix,
      ...
    }:
    let
      username = "beplyn";
      email = "me@beplyn.dev";
      forgejoHost = "codeberg.org";
      hostModule =
        hostname: themeName:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              username
              email
              forgejoHost
              themeName
              ;
          };
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            { nixpkgs.overlays = [ millennium.overlays.default ]; }
            ./hosts/common
            ./hosts/${hostname}
            stylix.nixosModules.stylix
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                inherit
                  inputs
                  username
                  email
                  forgejoHost
                  themeName
                  ;
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.sharedModules = [
                nixvim.homeModules.nixvim
                areofyl-fetch.homeManagerModules.default
                sops-nix.homeManagerModules.sops
              ];
              home-manager.users.${username} = {
                imports = [ ./users/${username} ];
                home.username = username;
                home.homeDirectory = "/home/${username}";
                home.stateVersion = "26.11";
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        "anvil-catppuccin" = hostModule "anvil" "catppuccin";
        "anvil-gruvbox" = hostModule "anvil" "gruvbox";
        "anvil-nord" = hostModule "anvil" "nord";
        "beacon-catppuccin" = hostModule "beacon" "catppuccin";
        "beacon-gruvbox" = hostModule "beacon" "gruvbox";
        "beacon-nord" = hostModule "beacon" "nord";
        "compass-catppuccin" = hostModule "compass" "catppuccin";
        "compass-gruvbox" = hostModule "compass" "gruvbox";
        "compass-nord" = hostModule "compass" "nord";
        "shulker-catppuccin" = hostModule "shulker" "catppuccin";
        "shulker-gruvbox" = hostModule "shulker" "gruvbox";
        "shulker-nord" = hostModule "shulker" "nord";
        default = hostModule "shulker" "catppuccin";
      };
    };
}
