{
  inputs =
  {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager =
    {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    vcal =
    {
      url = "github:beplyn/vcal";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    stylix =
    {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin-zen =
    {
      url = "github:catppuccin/zen-browser";
      flake = false;
    };

    catppuccin-vimium =
    {
      url = "github:catppuccin/vimium";
      flake = false;
    };

    cliamp =
    {
      url = "github:bjarneo/cliamp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glass-firefox =
    {
      url = "github:ChaosMx11/Glass-Firefox-Theme";
      flake = false;
    };

    speci-local =
    {
      url = "github:FCsab/speci-local";
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
