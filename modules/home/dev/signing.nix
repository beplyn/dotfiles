{ pkgs, ... }:

# per-host GPG signing and SSH keys come from `rebuild` (needs a terminal); public halves in keys/
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
