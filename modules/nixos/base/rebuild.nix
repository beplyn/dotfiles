{
  config,
  lib,
  pkgs,
  inputs,
  username,
  email,
  forgejoHost,
  themeName,
  ...
}:

let
  # rebuild [theme]: prompts for missing secrets, then switches to <host>-<theme>
  rebuild = pkgs.writeShellApplication
  {
    name = "rebuild";
    runtimeInputs = with pkgs;
    [
      git
      gnupg
      inputs.forgejo-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    text = lib.replaceStrings
      [ "@username@" "@email@" "@forgejoHost@" "@themeName@" "@hostName@" ]
      [ username email forgejoHost themeName config.networking.hostName ]
      (builtins.readFile ./rebuild.sh);
  };
in
{
  environment.systemPackages = [ rebuild ];
}
