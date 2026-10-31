{ pkgs, ... }:

# per-host GPG signing and SSH keys come from `rebuild` (needs a terminal) and stay out of the repo
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
