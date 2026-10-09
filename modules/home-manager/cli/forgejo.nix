{
  pkgs,
  inputs,
  config,
  username,
  forgejoHost,
  ...
}:

{
  sops.secrets."forgejo-token" = {
    path = "${config.home.homeDirectory}/.ssh/forgejo-token";
  };

  home.packages = [
    inputs.forgejo-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.sessionVariables = {
    FORGEJO_TOKEN_FILE = config.sops.secrets."forgejo-token".path;
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
