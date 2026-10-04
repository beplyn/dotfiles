{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    vim
    eza
    git
    github-copilot-cli
  ];
}
