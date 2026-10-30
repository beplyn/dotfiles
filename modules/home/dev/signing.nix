{ pkgs, ... }:

# GPG signing key comes from `rebuild` (needs a terminal); SSH keys: cli/ssh.nix
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
