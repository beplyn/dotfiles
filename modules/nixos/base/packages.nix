{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs;
  [
    vim
    eza
    git
  ];
}
