{
  config,
  lib,
  pkgs,
  inputs,
  subst,
  ...
}:

let
  # "#rrggbb" -> "R;G;B"
  toRgb =
    color:
    let
      hex = lib.removePrefix "#" color;
    in
    lib.concatMapStringsSep ";" (i: toString (lib.fromHexString (builtins.substring i 2 hex))) [ 0 2 4 ];

  ansi = color: "\\x1b[38;2;${toRgb color}m";
  reset = "\\x1b[0m";

  system = pkgs.stdenv.hostPlatform.system;
  upstreamFetch = inputs.areofyl-fetch.packages.${system}.default;

  patchedFetch = upstreamFetch.overrideAttrs (oldAttrs:
  {
    postPatch = (oldAttrs.postPatch or "")
      + subst (lib.mapAttrs (_: ansi) config.themes.palette // { inherit reset; }) (builtins.readFile ./fetch-patch.sh);
  });
in
{
  programs.fetch.enable = lib.mkForce false;
  home.packages = [ patchedFetch ];

  xdg.configFile."fetch/config".source = ./fetch.conf;

  xdg.configFile."fetch/logo.txt".source = ./fetch-logo.txt;
}
