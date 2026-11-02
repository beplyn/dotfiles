# Sine mod manager for LibreWolf, mirroring the zen flake's own sine.enable.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.librewolf;
  profile = "${cfg.profilesPath}/${cfg.profiles.default.path}";

  # same pins as Zen's sine.enable, so both run one Sine
  pins = (lib.importJSON "${inputs.zen-browser}/sources.json").addons.sine;
  engine = pkgs.fetchFromGitHub { inherit (pins.manager) owner repo rev hash; };
  bootloader = pkgs.fetchFromGitHub { inherit (pins.bootloader) owner repo rev hash; };

  engineVersion = pkgs.runCommand "sine-engine.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq '.updates[0]' ${engine}/engine.json > $out
  '';
in
{
  # LibreWolf already owns autoconfig (librewolf.cfg); the bootloader is appended to it
  programs.librewolf.package = pkgs.librewolf.override (old:
  {
    extraPrefsFiles = old.extraPrefsFiles or [ ] ++ [ "${bootloader}/program/config.js" ];
    extraAutoConfig = (old.extraAutoConfig or "") + ''
      pref("general.config.sandbox_enabled", false);
    '';
  });

  # Nix owns the engine; mods still install at runtime into chrome/sine-mods
  programs.librewolf.profiles.default.settings."sine.engine.auto-update" = false;

  home.file =
  {
    "${profile}/chrome/JS" =
    {
      source = "${engine}/src";
      recursive = true;
      force = true;
    };
    "${profile}/chrome/JS/locales" =
    {
      source = "${engine}/locales";
      recursive = true;
      force = true;
    };
    "${profile}/chrome/JS/engine.json" =
    {
      source = engineVersion;
      force = true;
    };
    "${profile}/chrome/utils" =
    {
      source = "${bootloader}/profile/utils";
      recursive = true;
      force = true;
    };
  };
}
