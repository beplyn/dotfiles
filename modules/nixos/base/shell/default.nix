{
  config,
  lib,
  themes,
  ...
}:

{
  programs.fish =
  {
    enable = true;
    shellAbbrs =
    {
      g = "git";
      tree = "eza --icons --tree --color=auto";
      trel = "eza --icons --tree -a -I \".git\" --color=auto --level=2";
      icat = "wezterm imgcat";
      # manual gc, also cleans the boot menu
      gc = "sudo nix-collect-garbage ${config.nix.gc.options} && sudo /run/current-system/bin/switch-to-configuration boot";

      ".." = "cd ..";
      "..." = "cd ../..";
    }
    # one per theme: `nord` -> rebuild nord
    // lib.genAttrs themes (t: "rebuild ${t}");
    shellAliases =
    {
      y = "yazi";
      lg = "lazygit";
      repo-update = "git fetch && git pull --rebase && git push";
      v = "nvim";
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

  # typos in fish and bash: an unknown command offers the closest match (fastftech -> fastfetch),
  # `f` fixes the last command, ctrl-x ctrl-x the one being typed
  programs.pay-respects =
  {
    enable = true;
    alias = "f";
  };
}
