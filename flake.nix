{
  inputs =
  {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # placeholders; real values via --override-input vars (docs/vars.md)
    vars =
    {
      url = "path:./vars";
      flake = false;
    };

    home-manager =
    {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim";

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
      hosts = lib.attrNames (lib.filterAttrs (n: t: t == "directory") (builtins.readDir ./hosts));
      themes =
      [
        "catppuccin"
        "gruvbox"
        "nord"
      ];
      # an auto-rebuild or a plain nixos-rebuild without the override would build "user"
      # at example.com; refuse instead
      vars =
        let
          v = builtins.fromTOML (builtins.readFile "${inputs.vars}/vars.toml");
        in
        if v.placeholder or false then
          throw ''
            vars: only the repo's placeholders (docs/vars.md). `rebuild` asks for the real ones;
            a rebuild from before vars can't, so once, from the checkout:
              nix shell nixpkgs#yq-go -c bash /etc/nixos/modules/nixos/base/rebuild/vars.sh /etc/nixos/vars/vars.toml /var/secrets/dotfiles <host>
              sudo nixos-rebuild switch --flake /etc/nixos#<host>-<theme> --override-input vars path:/var/secrets/dotfiles
            and plain `rebuild` from then on
          ''
        else
          v;
      mkHost = import ./lib/mkHost.nix
      {
        inherit inputs themes;
        inherit (vars) username email domain repo;
        # lan.* is asked for only on hosts with staticLan (hosts/<name>/meta.nix)
        lan = vars.lan or { address = ""; gateway = ""; subnet = ""; };
        wgKeys = vars.wireguard or { };
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
