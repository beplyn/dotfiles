{
  username,
  email,
  osConfig,
  headless,
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
      ui.editor = if headless then "vim" else "nvim";
      signing =
      {
        behavior = "own";
        backend = "gpg";
        key = "=${username} (${osConfig.networking.hostName}) <${email}>";
      };
    };
  };
}
