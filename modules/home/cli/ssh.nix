{
  config,
  lib,
  pkgs,
  username,
  forgejoHost,
  ...
}:

let
  sshDir = "${config.home.homeDirectory}/.ssh";
  # git hosts, each with its own key: codeberg.org -> ~/.ssh/codeberg-auth
  gitHosts = [ forgejoHost "gitlab.com" ];
  keyFile = host: "${sshDir}/${lib.head (lib.splitString "." host)}-auth";
in
{
  programs.ssh =
  {
    enable = true;
    enableDefaultConfig = false;
    settings = lib.genAttrs gitHosts (host:
    {
      hostname = host;
      user = "git";
      identityFile = keyFile host;
      identitiesOnly = true;
    });
  };

  # missing keys are generated; upload the .pub to the host afterwards
  home.activation.generateSshKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (host: ''
      if [ ! -e "${keyFile host}" ]; then
        echo "No SSH key found at ${keyFile host}, generating one..."
        run ${pkgs.coreutils}/bin/mkdir -p "${sshDir}"
        run ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -f "${keyFile host}" -N "" -C "${username}@${host}"
      fi
    '') gitHosts
  );
}
