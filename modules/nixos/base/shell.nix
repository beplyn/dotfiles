{
  config,
  ...
}:
let
  themeSwitch = "rebuild ";
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
      # manual gc, also cleans the boot menu
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
