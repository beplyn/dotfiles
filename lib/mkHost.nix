# One host/theme system plus Home Manager; specialArgs are shared with HM.
{
  inputs,
  username,
  email,
  forgejoHost,
  # servers: no GUI
  headlessHosts ? [ ],
}:

hostname: themeName:

let
  inherit (inputs) nixpkgs home-manager;
  headless = builtins.elem hostname headlessHosts;
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
in
nixpkgs.lib.nixosSystem {
  inherit specialArgs;
  modules = [
    { nixpkgs.hostPlatform = "x86_64-linux"; }
    { nixpkgs.overlays = [ inputs.millennium.overlays.default ]; }
    ../hosts/common
    ../hosts/${hostname}
  ]
  ++ nixpkgs.lib.optional (!headless) inputs.niri.nixosModules.niri
  ++ [
    inputs.stylix.nixosModules.stylix
    home-manager.nixosModules.home-manager
    {
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bk";
      home-manager.overwriteBackup = true;

      home-manager.sharedModules = [
        inputs.nixvim.homeModules.nixvim
        inputs.areofyl-fetch.homeManagerModules.default
      ];
      home-manager.users.${username}.imports = [ ../users/${username} ];
    }
  ];
}
