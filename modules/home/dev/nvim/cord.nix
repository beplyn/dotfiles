{ pkgs, ... }:

let
  # nixpkgs has 2.2.7, the classic theme came in 2.3
  version = "2.3.29";
  src = pkgs.fetchFromGitHub
  {
    owner = "vyfor";
    repo = "cord.nvim";
    tag = "v${version}";
    hash = "sha256-zQNkfw3YrEvs9JMgC5UnVE09S/bCIRT+R1j4KaAA0Kc=";
  };

  server = pkgs.rustPlatform.buildRustPackage
  {
    pname = "cord";
    inherit src version;
    # plugin checks the server against this file, it lags behind Cargo.toml
    postPatch = ''
      echo -n ${version} > .github/server-version.txt
    '';
    cargoHash = "sha256-f2bYDfWFfOm2H4iy0FS4g3NFW7uTB5/1CE7AQSr5llM=";
    # nightly features
    RUSTC_BOOTSTRAP = 1;
    meta.mainProgram = "cord";
  };

  plugin = pkgs.vimUtils.buildVimPlugin
  {
    pname = "cord.nvim";
    inherit src version;
    # server from the store, not stdpath('data')
    postPatch = ''
      substituteInPlace lua/cord/server/fs/init.lua \
        --replace-fail "or M.get_data_path()" "or '${server}'"
    '';
    # complains on require when CORD_LOG_FILE is unset
    nvimSkipModules = [ "cord.api.log.file" ];
  };
in
{
  # discord rich presence, equibop's arrpc takes it
  programs.nixvim.plugins.cord =
  {
    enable = true;
    package = plugin;
    settings =
    {
      display.theme = "classic";
      # the default fetches a server into the read-only store path,
      # fails and shuts the running one down
      advanced.server.update = "none";
    };
  };
}
