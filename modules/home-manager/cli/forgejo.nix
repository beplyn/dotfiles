{
  pkgs,
  inputs,
  config,
  ...
}:

{
  home.packages = [
    inputs.forgejo-cli.packages.${pkgs.system}.default
  ];

  home.sessionVariables = {
    FORGEJO_TOKEN_FILE = "${config.home.homeDirectory}/.ssh/forgejo-token";
    FORGEJO_API_URL = "https://codeberg.org/api/v1";
  };

  xdg.configFile."forgejo-cli/config.yml".text = ''
    default_host: "codeberg.org"
    hosts:
      codeberg.org:
        user: "beplyn"
        url: "https://codeberg.org"
  '';
}
