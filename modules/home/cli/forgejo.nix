{
  pkgs,
  inputs,
  config,
  username,
  forgejoHost,
  ...
}:

{
  home.packages =
  [
    inputs.forgejo-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.sessionVariables =
  {
    FORGEJO_API_URL = "https://${forgejoHost}/api/v1";
  };

  xdg.configFile."forgejo-cli/config.yml".text = ''
    default_host: "${forgejoHost}"
    hosts:
      ${forgejoHost}:
        user: "${username}"
        url: "https://${forgejoHost}"
  '';
}
