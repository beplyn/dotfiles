{
  inputs,
  pkgs,
  themeName,
  ...
}:

let
  beacon = inputs.self.nixosConfigurations."beacon-${themeName}".config;

  mediaUpload = pkgs.writeShellApplication
  {
    name = "media-upload";
    runtimeInputs = with pkgs;
    [
      rsync
      openssh
    ];
    runtimeEnv =
    {
      BEACON_HOST = beacon.proxy.domain;
      BEACON_PORT = toString (builtins.head beacon.services.openssh.ports);
      BEACON_BULK = beacon.k3s.storage.bulk;
    };
    text = builtins.readFile ./media-upload.sh;
  };
in
{
  home.packages = [ mediaUpload ];
}
