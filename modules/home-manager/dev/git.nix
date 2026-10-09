{
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
      key = "me@beplyn.dev";
      signByDefault = true;
    };
  };
}
