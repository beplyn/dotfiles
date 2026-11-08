{
  subst,
  username,
  ...
}:

{
  security.sudo =
  {
    wheelNeedsPassword = true;
    # only wheel can even run the setuid binary
    execWheelOnly = true;
    extraConfig = subst { inherit username; } (builtins.readFile ./sudoers);
  };
}
