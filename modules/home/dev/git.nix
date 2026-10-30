{
  username,
  email,
  forgejoHost,
  ...
}:

{
  programs.git =
  {
    enable = true;
    settings =
    {
      user =
      {
        name = username;
        inherit email;
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      core.editor = "nvim";
      safe =
      {
        directory = [ "/etc/nixos" ];
      };
      url."git@${forgejoHost}:".pushInsteadOf = "https://${forgejoHost}/";
      alias =
      {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
    signing =
    {
      key = email;
      signByDefault = true;
    };
  };
}
