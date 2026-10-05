{
  config,
  ...
}:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "beplyn";
        email = "me@beplyn.dev";
      };
      init.defaultBranch = "master";
      core.editor = "nvim";
      safe = {
        directory = [ "/etc/nixos" ];
      };
    };
    signing = {
      key = "${config.home.homeDirectory}/.ssh/git-signing-key.pub";
      signByDefault = true;
      format = "ssh";
    };
  };
}
