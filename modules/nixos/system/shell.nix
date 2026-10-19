{
  config,
  ...
}:

{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      tree = "eza --icons --tree --color=auto";
      trel = "eza --icons --tree -a -I \".git\" --color=auto --level=2";
      icat = "kitty +kitten icat";
      purgeGarbage = "nix store optimise && \
        sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +3 && \
        nix-env --delete-generations +3 && \
        nix-env -p ~/.local/state/nix/profiles/home-manager --delete-generations +3 2>/dev/null || true \
        sudo nix-collect-garbage \
        sudo /run/current-system/bin/switch-to-configuration boot";

      "." = "cd ..";
      ".." = "cd ../../";
      catppuccin = "cd /etc/nixos; git add . && sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}-catppuccin";
      nord = "cd /etc/nixos; git add . && sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}-nord";
      gruvbox = "cd /etc/nixos; git add . && sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}-gruvbox";
    };
    shellAliases = {
      vim = "nvim";
      nano = "nvim";
      ls = "eza --icons --color=auto -a";
      grep = "rg --color=auto";
    };
    generateCompletions = true;

    shellInit = ''
      set -gx GPG_TTY (tty)
    '';
    interactiveShellInit = ''
      function __prepend_sudo
        set -l cmd (commandline)
        if test -z "$cmd"
          set cmd $history[1]
        end
        if test -z "$cmd"
          return
        end
        if string match -q "sudo -E *" "$cmd"
          commandline -r (string sub -s 9 "$cmd")
        else if string match -q "sudo *" "$cmd"
          commandline -r (string replace -r '^sudo ' 'sudo -E ' "$cmd")
        else
          commandline -r "sudo -E $cmd"
        end
      end
      bind \es __prepend_sudo

      function __append_fzf
        set -l cmd (commandline)
        if test -z "$cmd"
          return
        end
        if string match -q "*q (fzf)" "$cmd"
          commandline -r (string replace -r ' \(fzf\)$' "$cmd")
        else if string match -q "* " "$cmd"
          commandline -r "$cmd(fzf)"
        else
          commandline -r "$cmd (fzf)"
        end
      end
      bind \ef __append_fzf

      fish_add_path --prepend --move \
        $HOME/.nix-profile/bin \
        /nix/var/nix/profiles/default/bin

      set -g fish_greeting ""
      fastfetch
    '';
  };
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
