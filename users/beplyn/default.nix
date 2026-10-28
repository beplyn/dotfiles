{ username, ... }:

{
  imports = [ ../../modules/home ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.11";

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
}
