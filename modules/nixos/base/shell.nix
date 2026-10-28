{
  config,
  ...
}:
let
  themeSwitch = "cd /etc/nixos; git add . && sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}-";
in
{
  programs.fish =
  {
    enable = true;
    shellAbbrs =
    {
      g = "git";
      tree = "eza --icons --tree --color=auto";
      trel = "eza --icons --tree -a -I \".git\" --color=auto --level=2";
      icat = "kitty +kitten icat";
      # On-demand version of nix.gc; also drops removed generations from the boot menu.
      purgeGarbage = "sudo nix-collect-garbage --delete-older-than 14d && sudo /run/current-system/bin/switch-to-configuration boot";

      "." = "cd ..";
      ".." = "cd ../../";
      catppuccin = themeSwitch + "catppuccin";
      nord = themeSwitch + "nord";
      gruvbox = themeSwitch + "gruvbox";
    };
    shellAliases =
    {
      vim = "nvim";
      nano = "nvim";
      ls = "eza --icons --color=auto -a";
      grep = "rg --color=auto";
    };
    generateCompletions = true;

    shellInit = ''
      set -gx GPG_TTY (tty)
    '';
    interactiveShellInit = builtins.readFile ./init.fish;
  };
  programs.zoxide =
  {
    enable = true;
    enableFishIntegration = true;
  };
}
