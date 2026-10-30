{
  config,
  pkgs,
  inputs,
  subst,
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
    text = subst
      {
        inherit username email forgejoHost themeName;
        hostName = config.networking.hostName;
      }
      (builtins.readFile ./rebuild.sh);
  };
in
{
  environment.systemPackages = [ rebuild ];
}
