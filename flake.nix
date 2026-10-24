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

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri 26.04 with a liquid-glass background effect. The niri source stays
    # pinned (the overlay replaces whole upstream files), but it must build
    # against our nixpkgs: niri dlopens mesa from /run/opengl-driver, which
    # needs the system glibc. With its own nixpkgs GBM fails to load and niri
    # starts without outputs.
    niri-glass = {
      url = "github:zaroutt/Niri-glass";
      inputs.niri.inputs.nixpkgs.follows = "nixpkgs";
    };

    nirimation = {
      url = "git+https://codeberg.org/beplyn/nirimation";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nixvim,
      areofyl-fetch,
      millennium,
      sops-nix,
      niri,
      stylix,
      ...
    }:
    let
      username = "beplyn";
      email = "me@beplyn.dev";
      forgejoHost = "codeberg.org";
      hosts = [
        "anvil"
        "beacon"
        "compass"
        "shulker"
      ];
      themes = [
        "catppuccin"
        "gruvbox"
        "nord"
      ];
      # Servers: no display manager, compositor, fonts or GUI apps.
      headlessHosts = [ "beacon" ];
      hostModule =
        hostname: themeName:
        let
          headless = builtins.elem hostname headlessHosts;
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              username
              email
              forgejoHost
              themeName
              headless
              ;
          };
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            { nixpkgs.overlays = [ millennium.overlays.default ]; }
            ./hosts/common
            ./hosts/${hostname}
          ]
          ++ nixpkgs.lib.optional (!headless) niri.nixosModules.niri
          ++ [
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
                  headless
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
      nixosConfigurations =
        nixpkgs.lib.listToAttrs (
          map (h: {
            name = "${h.host}-${h.theme}";
            value = hostModule h.host h.theme;
          }) (nixpkgs.lib.cartesianProduct { host = hosts; theme = themes; })
        )
        // {
          default = hostModule "shulker" "catppuccin";
        };
    };
}
