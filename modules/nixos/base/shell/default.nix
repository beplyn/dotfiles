{
  config,
  lib,
  themes,
  headless,
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
      v = if headless then "vim" else "nvim";
      ls = "eza --icons --color=auto -a";
      grep = "rg --color=auto";
    };
    generateCompletions = true;

    shellInit = ''
      set -gx GPG_TTY (tty)
    '';
    interactiveShellInit = builtins.readFile ./init.fish;
  };
  # zsh's config is home-manager's (cli/zsh); NixOS only wires its /etc/zshrc hooks
  programs.zsh =
  {
    enable = true;
    # home-manager runs compinit
    enableCompletion = false;
  };

  programs.zoxide =
  {
    enable = true;
    enableFishIntegration = true;
  };

  # typo fixes: closest match, `f` for the last command, ctrl-x ctrl-x for this one
  programs.pay-respects =
  {
    enable = true;
    alias = "f";
  };
}
