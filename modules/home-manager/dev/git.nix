{
  username,
  email,
  ...
}:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = username;
        inherit email;
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      core.editor = "nvim";
      safe = {
        directory = [ "/etc/nixos" ];
      };
    };
    signing = {
      key = email;
      signByDefault = true;
    };
  };
}
