{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs;
  [
    # for vimtutor; `vim` itself is aliased to nvim
    vim
    git
    # system-wide shell aliases use it, root shells included
    eza
  ];
}
