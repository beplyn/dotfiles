{
  ...
}:

{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      icat = "kitty +kitten icat";
      rebuild = "sudo nixos-rebuild switch --flake .#";
      "." = "cd ..";
      ".." = "cd ../../";
    };
    shellAliases = {
      nano = "nvim";
      ls = "eza --icons --color=auto";
      grep = "rg --color=auto";
    };
    generateCompletions = true;
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
      palette = "catppuccin_mocha";

      palettes = {
        powerlevel10k = {
          p10k_directory = "#00afff";
          p10k_green = "#5fd700";
          p10k_red = "#ff0000";
          p10k_modified = "#d7af00";
          p10k_duration = "#87875f";
          p10k_time = "#5f8787";
          p10k_surface = "#444444";
          p10k_separator = "#949494";
          p10k_foreground = "#e4e4e4";
          p10k_outline = "#6c6c6c";
          p10k_black = "#080808";
          p10k_ansi_black = "#2e3436";
          p10k_ansi_green = "#4e9a06";
          p10k_ansi_yellow = "#c4a000";
          p10k_ansi_blue = "#3465a4";
          p10k_ansi_white = "#d3d7cf";
          p10k_blue = "#005faf";
          p10k_yellow = "#d7af00";
          p10k_white = "#d0d0d0";
        };

        catppuccin_mocha = {
          rosewater = "#f5e0dc";
          flamingo = "#f2cdcd";
          pink = "#f5c2e7";
          mauve = "#cba6f7";
          red = "#f38ba8";
          maroon = "#eba0ac";
          peach = "#fab387";
          yellow = "#f9e2af";
          green = "#a6e3a1";
          teal = "#94e2d5";
          sky = "#89dceb";
          sapphire = "#74c7ec";
          blue = "#89b4fa";
          lavender = "#b4befe";
          text = "#cdd6f4";
          subtext1 = "#bac2de";
          subtext0 = "#a6adc8";
          overlay2 = "#9399b2";
          overlay1 = "#7f849c";
          overlay0 = "#6c7086";
          surface2 = "#585b70";
          surface1 = "#45475a";
          surface0 = "#313244";
          base = "#1e1e2e";
          mantle = "#181825";
          crust = "#11111b";
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
          NixOS = ""; # Corrected to the standard NixOS Nerd Font glyph
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
