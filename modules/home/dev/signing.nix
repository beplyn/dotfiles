{ pkgs, ... }:

# per-host GPG and SSH keys: made by `rebuild`, never in the repo
{
  programs.gpg.enable = true;

  services.gpg-agent =
  {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  home.packages = with pkgs;
  [
    gpg-tui
  ];
}
