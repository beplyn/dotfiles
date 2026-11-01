{
  config,
  lib,
  pkgs,
  inputs,
  subst,
  username,
  email,
  forgejoHost,
  themeName,
  headless,
  ...
}:

let
  # rebuild [theme]: prompts for missing secrets and ~/.pfp, then switches to <host>-<theme>
  rebuild = pkgs.writeShellApplication
  {
    name = "rebuild";
    runtimeInputs = with pkgs;
    [
      git
      gnupg
      imagemagick
      openssh
      inputs.forgejo-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    text = subst
      {
        inherit username email forgejoHost themeName;
        hostName = config.networking.hostName;
        desktop = lib.boolToString (!headless);
      }
      (builtins.readFile ./rebuild.sh);
  };
in
{
  environment.systemPackages = [ rebuild ];
}
