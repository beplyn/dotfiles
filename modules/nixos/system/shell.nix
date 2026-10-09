{ config, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
  palette = {
    background = c.base00;
    surface = c.base02;
    surfaceBright = c.base03;
    red = c.base08;
    yellow = c.base0A;
    green = c.base0B;
    aqua = c.base0C;
    blue = c.base0D;
    purple = c.base0E;
    text = c.base05;
    muted = c.base03;
    accent = c.base0E;
    error = c.base08;
    success = c.base0B;
    warning = c.base0A;
  };
in

{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      tree = "eza --icons --tree --color=auto";
      trel = "eza --icons --tree -a -I \".git\" --color=auto --level=2";
      icat = "kitty +kitten icat";
      "." = "cd ..";
      ".." = "cd ../../";
      nrbs-catppuccin = "sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}-catppuccin";
      nrbs-nord = "sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}-nord";
      nrbs-gruvbox = "sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}-gruvbox";
    };
    shellAliases = {
      vim = "nvim";
      nano = "nvim";
      ls = "eza --icons --color=auto";
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

  programs.starship = {
    enable = true;
    interactiveOnly = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      format = "$fill[](mauve)$os$directory$git_branch$git_status[([](mauve bg:surface2)$cmd_duration[](mauve))](crust bg:mauve)[─╮](fg:overlay0)$line_break[$character](mauve)";
      right_format = "[─╯](fg:overlay0)";
      add_newline = true;
      palette = "theme";

      palettes = {
        theme = {
          mauve = palette.accent;
          red = palette.error;
          yellow = palette.warning;
          green = palette.success;
          blue = palette.blue;
          teal = palette.aqua;
          purple = palette.purple;
          text = palette.text;
          overlay0 = palette.muted;
          surface2 = palette.surfaceBright;
          surface1 = palette.surface;
          crust = palette.background;
        };
      };

      character = {
        success_symbol = "[❯](bold fg:surface2)";
        error_symbol = "[❯](bold fg:red)";
        vimcmd_symbol = "[❮](bold fg:surface2)";
        format = "▶ ";
      };

      cmd_duration = {
        format = "[$duration]($style)";
        min_time = 1500;
        style = "bold crust bg:mauve";
      };

      directory = {
        format = "[  $path ]($style)[](inverted surface2 bg:crust)";
        style = "bold mauve bg:crust";
        truncate_to_repo = false;
        truncation_symbol = "…/";
        repo_root_format = "[$before_root_path]($style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
      };

      fill = {
        style = "fg:overlay0";
        symbol = " ";
      };

      git_branch = {
        style = "red bg:surface2";
        symbol = "";
        format = "[( $branch $symbol (:$remote_branch))]($style)";
      };

      git_status = {
        format = "[$all_status$ahead_behind ]($style)";
        style = "bold purple bg:surface2";
      };

      jobs = {
        format = "[ $symbol[$number](bold crust bg:bright-blue)[ ](bold crust bg:bright-blue)]($style)";
        symbol = "[✦](crust bg:bright-blue)";
        style = "bold crust bg:mauve";
      };

      os = {
        disabled = false;
        format = "[$symbol]($style)[](mauve bg:crust)";
        style = "crust bg:mauve";
        symbols = {
          Arch = "";
          NixOS = "";
        };
      };

      status = {
        disabled = false;
        format = "[ $symbol$status ]($style)";
        symbol = "✘";
        style = "bold crust bg:mauve";
        map_symbol = true;
      };

      time = {
        disabled = false;
        format = "[](bold red bg:bright-blue)[ at  $time ](surface0 bg:red)";
        time_format = "%H:%M:%S";
        style = "bold crust bg:mauve";
      };
    };
  };
}
