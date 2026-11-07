{
  username,
  email,
  osConfig,
  ...
}:
{
  # same identity and per-host GPG key as git
  programs.jujutsu =
  {
    enable = true;
    settings =
    {
      user =
      {
        name = username;
        inherit email;
      };
      ui.editor = "nvim";
      signing =
      {
        behavior = "own";
        backend = "gpg";
        key = "=${username} (${osConfig.networking.hostName}) <${email}>";
      };
    };
  };
}
