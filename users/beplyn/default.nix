{ ... }:

{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  imports = [ ../../modules/home-manager ];
}
