# One host/theme system plus Home Manager; specialArgs are shared with HM.
{
  inputs,
  username,
  email,
  # beacon serves it; the other hosts are its clients
  domain,
  # this repo's https URL
  repo,
  # beacon's static LAN address, gateway and subnet; empty elsewhere
  lan,
  # wg0 public keys by host name, from the vars file; empty until filled in
  wgKeys,
  # every theme in the flake, for the rebuild shortcuts
  themes,
  # per-theme data, see lib/themes.nix
  themeTable,
}:

hostname: themeName:

let
  inherit (inputs) nixpkgs home-manager;
  # optional hosts/<name>/meta.nix: headless, staticLan (docs/layout.md)
  metaFile = ../hosts + "/${hostname}/meta.nix";
  meta = if builtins.pathExists metaFile then import metaFile else { };
  headless = meta.headless or false;
  staticLan = meta.staticLan or false;
  # https://<host>/<owner>/<name>.git
  forgejoHost = builtins.head (builtins.match "https?://([^/]+)/.*" repo);
  specialArgs =
  {
    inherit
      inputs
      username
      email
      domain
      repo
      lan
      wgKeys
      forgejoHost
      themes
      themeTable
      themeName
      headless
      staticLan
      ;
    subst = import ./subst.nix { inherit (nixpkgs) lib; };
  };
in
nixpkgs.lib.nixosSystem
{
  inherit specialArgs;
  modules =
  [
    { nixpkgs.hostPlatform = "x86_64-linux"; }
    ../modules/nixos
    ../hosts/${hostname}
    # built on our nixpkgs, whose cargo hook links -sys crates to system libs
    {
      nixpkgs.overlays =
      [
        (final: prev:
        let
          withSystemLibs = drv: libs: drv.overrideAttrs (old:
          {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.pkg-config ];
            buildInputs = (old.buildInputs or [ ]) ++ libs;
          });
          system = final.stdenv.hostPlatform.system;
        in
        {
          netspd = withSystemLibs inputs.netspd.packages.${system}.default [ final.aws-lc ];
          # upstream player test compares EOF error strings and is flaky
          cliamp = inputs.cliamp.packages.${system}.default.overrideAttrs { doCheck = false; };
          speci-local = inputs.speci-local.packages.${system}.default;
          serein = inputs.serein.packages.${system}.default;
        })
      ];
    }
  ]
  # Steam (Millennium) only with a display
  ++ nixpkgs.lib.optional (!headless)
    { nixpkgs.overlays = [ inputs.millennium.overlays.default ]; }
  ++
  [
    inputs.stylix.nixosModules.stylix
    home-manager.nixosModules.home-manager
    {
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bk";
      home-manager.overwriteBackup = true;

      home-manager.sharedModules =
      [
        inputs.nixvim.homeModules.nixvim
      ];
      home-manager.users.${username}.imports = [ ../users/me ];
    }
  ];
}
