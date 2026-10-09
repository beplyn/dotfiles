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
