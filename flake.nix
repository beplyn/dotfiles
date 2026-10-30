{
  inputs =
  {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager =
    {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    forgejo-cli =
    {
      url = "git+https://codeberg.org/forgejo-contrib/forgejo-cli.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # no follows: nixvim warns when its nixpkgs pin is overridden
    nixvim.url = "github:nix-community/nixvim";

    areofyl-fetch =
    {
      url = "github:areofyl/fetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    millennium =
    {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    netspd =
    {
      url = "github:TarunVishwakarma1/netspd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri =
    {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri-glass; follows our nixpkgs so mesa/GBM loads (system glibc)
    niri-glass =
    {
      url = "github:zaroutt/Niri-glass";
      inputs.niri.inputs.nixpkgs.follows = "nixpkgs";
    };

    nirimation =
    {
      url = "git+https://codeberg.org/beplyn/nirimation";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix =
    {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser =
    {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      # every directory in hosts/ except the shared one
      hosts = lib.attrNames (lib.filterAttrs (n: t: t == "directory" && n != "common") (builtins.readDir ./hosts));
      themes =
      [
        "catppuccin"
        "gruvbox"
        "nord"
      ];
      mkHost = import ./lib/mkHost.nix
      {
        inherit inputs themes;
        username = "beplyn";
        email = "me@beplyn.dev";
        forgejoHost = "codeberg.org";
        headlessHosts = [ "beacon" ];
      };
    in
    {
      nixosConfigurations = lib.listToAttrs (
        map
          (h:
          {
            name = "${h.host}-${h.theme}";
            value = mkHost h.host h.theme;
          })
          (lib.cartesianProduct { host = hosts; theme = themes; })
      );
    };
}
