{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  colors = lib.filterAttrs (n: _: builtins.match "base0[0-9A-F]" n != null) config.lib.stylix.colors;

  # hex -> "R;G;B"
  toRgb =
    color:
    lib.concatStringsSep ";" (
      builtins.map (part: toString (lib.fromHexString part))
      [
        (builtins.substring 0 2 color)
        (builtins.substring 2 2 color)
        (builtins.substring 4 2 color)
      ]
    );

  ansi = color: "\\x1b[38;2;${toRgb color}m";
  reset = "\\x1b[0m";

  system = pkgs.stdenv.hostPlatform.system;
  upstreamFetch = inputs.areofyl-fetch.packages.${system}.default;

  patchedFetch = upstreamFetch.overrideAttrs (oldAttrs:
  {
    postPatch = (oldAttrs.postPatch or "") + lib.replaceStrings
      (map (n: "@${n}@") (lib.attrNames colors) ++ [ "@reset@" ])
      (map ansi (lib.attrValues colors) ++ [ reset ])
      (builtins.readFile ./fetch-patch.sh);
  });
in
{
  programs.fetch.enable = lib.mkForce false;
  home.packages = [ patchedFetch ];

  xdg.configFile."fetch/config".text = builtins.readFile ./fetch.conf;

  home.file.".config/fetch/logo.txt".text = builtins.readFile ./fetch-logo.txt;
}
