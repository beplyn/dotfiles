{
  pkgs,
  inputs,
  config,
  username,
  codebergHost,
  ...
}:

{
  sops.secrets."forgejo-token" = {
    path = "${config.home.homeDirectory}/.ssh/forgejo-token";
  };

  home.packages = [
    inputs.forgejo-cli.packages.${pkgs.system}.default
  ];

  home.sessionVariables = {
    FORGEJO_TOKEN_FILE = config.sops.secrets."forgejo-token".path;
    FORGEJO_API_URL = "https://${codebergHost}/api/v1";
  };

  xdg.configFile."forgejo-cli/config.yml".text = ''
    default_host: "${codebergHost}"
    hosts:
      ${codebergHost}:
        user: "${username}"
        url: "https://${codebergHost}"
  '';
}
