{
  lib,
  osConfig,
  pkgs,
  ...
}:

# mango reads config.conf; each part is its own file, checked with `mango -p`
let
  mango = osConfig.programs.mango.package;
  parts =
  [
    "settings"
    "outputs"
    "binds"
  ];
in
{
  imports =
  [
    ./binds.nix
    ./outputs.nix
    ./settings.nix
  ];

  # config text -> a store file mango has parsed
  lib.haku.mangoConf = name: text: pkgs.runCommand "mango-${name}.conf" { } ''
    cp ${pkgs.writeText "mango-${name}.conf" text} "$out"
    ${lib.getExe mango} -c "$out" -p
  '';

  xdg.configFile."mango/config.conf".text = lib.concatMapStrings (p: "source=~/.config/mango/${p}.conf\n") parts;
}
