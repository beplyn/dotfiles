{
  config,
  lib,
  subst,
  ...
}:

# Replaces fastfetch (still there as `ff`). Shown on first shell per login,
# over ssh, else 1 in `chance`.
let
  vars = lib.mapAttrs (_: lib.removePrefix "#") config.themes.palette // {
    chance = "4";
    diskWarn = "85"; # percent
  };
in
{
  programs.fish.shellAbbrs.ff = "fastfetch";

  programs.fish.interactiveShellInit = lib.mkAfter (subst vars (builtins.readFile ./greeting.fish));
}
