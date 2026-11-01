# One host/theme system plus Home Manager; specialArgs are shared with HM.
{
  inputs,
  username,
  email,
  forgejoHost,
  # every theme in the flake, for the rebuild shortcuts
  themes,
  # servers: no GUI
  headlessHosts ? [ ],
}:

hostname: themeName:

let
  inherit (inputs) nixpkgs home-manager;
  headless = builtins.elem hostname headlessHosts;
  specialArgs =
  {
    inherit
      inputs
      username
      email
      forgejoHost
      themes
      themeName
      headless
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
    ../hosts/common
    ../hosts/${hostname}
  ]
  # Steam (Millennium) and niri only with a display
  ++ nixpkgs.lib.optionals (!headless)
  [
    { nixpkgs.overlays = [ inputs.millennium.overlays.default ]; }
    inputs.niri.nixosModules.niri
  ]
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
        inputs.areofyl-fetch.homeManagerModules.default
      ];
      home-manager.users.${username}.imports = [ ../users/${username} ];
    }
  ];
}
