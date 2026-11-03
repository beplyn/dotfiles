{ config, lib, ... }:

{
  # off: claude-code, the MS fonts and Steam are left out
  options.unfree.enable = lib.mkOption
  {
    type = lib.types.bool;
    default = true;
    description = "Unfree packages from nixpkgs.";
  };

  config.nixpkgs.config.allowUnfree = config.unfree.enable;
}
