{
  config,
  lib,
  pkgs,
  subst,
  headless,
  ...
}:

# replaces fastfetch (`ff`); first shell per login, over ssh, else 1 in `chance`
# a cfonts banner rolls on its own, 1 in `bannerChance`, like `fun` minus huge
let
  vars = lib.mapAttrs (_: lib.removePrefix "#") config.themes.palette //
  {
    chance = "4";
    bannerChance = "10";
    cfonts = lib.getExe pkgs.cfonts;
    diskWarn = "85"; # percent
  };
in
{
  # fastfetch is desktop-only (modules/home/cli)
  programs.fish.shellAbbrs.ff = lib.mkIf (!headless) "fastfetch";

  programs.fish.interactiveShellInit = lib.mkAfter (subst vars (builtins.readFile ./greeting.fish));
}
