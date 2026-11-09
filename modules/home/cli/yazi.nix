{ config, pkgs, ... }:

let
  p = config.themes.palette;

  # ctrl+/ arrives as <C-/> with the kitty protocol, as <C-7> (0x1f) without
  helpKeys = run:
    map (on: { inherit on run; desc = "Keybinds"; }) [ "<C-/>" "<C-7>" ];
in
{
  programs.yazi =
  {
    enable = true;
    enableFishIntegration = true;
    extraPackages = with pkgs;
    [
      glow
      lazygit
      ouch
      starship
      wl-clipboard
    ];
    plugins = with pkgs.yaziPlugins;
    {
      inherit chmod jump-to-char lazygit mount ouch piper smart-enter smart-filter toggle-pane wl-clipboard;
      full-border =
      {
        package = full-border;
        setup = true;
      };
      git =
      {
        package = git;
        setup = true;
        settings.order = 1500;
      };
      starship =
      {
        package = starship;
        setup = true;
      };
    };
    keymap =
    {
      mgr.prepend_keymap =
      [
        {
          on = "<C-h>";
          run = "hidden toggle";
          desc = "Toggle hidden files";
        }
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = "f";
          run = "plugin jump-to-char";
          desc = "Jump to char";
        }
        {
          on = "F";
          run = "plugin smart-filter";
          desc = "Smart filter";
        }
        {
          on = "T";
          run = "plugin toggle-pane max-preview";
          desc = "Maximize or restore the preview pane";
        }
        {
          on = "M";
          run = "plugin mount";
          desc = "Mount manager";
        }
        {
          on = [ "c" "m" ];
          run = "plugin chmod";
          desc = "Chmod on selected files";
        }
        {
          on = [ "g" "i" ];
          run = "plugin lazygit";
          desc = "Lazygit";
        }
        {
          on = "<C-y>";
          run = "plugin wl-clipboard";
          desc = "Copy files to the system clipboard";
        }
        {
          on = "C";
          run = "plugin ouch tar.gz";
          desc = "Compress, tar.gz unless the name says otherwise";
        }
      ] ++ helpKeys "help";
      tasks.prepend_keymap = helpKeys "help";
      spot.prepend_keymap = helpKeys "help";
      pick.prepend_keymap = helpKeys "help";
      help.prepend_keymap = helpKeys "close";
    };
    settings =
    {
      mgr =
      {
        show_hidden = false;
      };
      plugin =
      {
        prepend_fetchers =
        [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
        ];
        prepend_previewers =
        [
          {
            url = "*.md";
            run = ''piper -- CLICOLOR_FORCE=1 glow -w=$w -s="${config.xdg.configHome}/glow/stylix.json" "$1"'';
          }
          {
            mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
            run = "ouch";
          }
        ];
      };
      opener =
      {
        edit =
        [
          {
            run = "nvim %s";
            block = true;
            for = "unix";
          }
        ];
        # binary in its own wezterm window with a shell left behind; it ignores
        # SIGHUP so a gui app outlives the window, but stays in the foreground
        # so stdin (scanf) still works
        run =
        [
          {
            run = ''wezterm start --cwd %d1 -- fish -c 'env --ignore-signal=HUP $argv[1]; echo "[exit $status]"; exec fish' %s1'';
            orphan = true;
            desc = "Run in wezterm";
            for = "unix";
          }
        ];
        # same, through bash, so a script without +x runs too
        run-sh =
        [
          {
            run = ''wezterm start --cwd %d1 -- fish -c 'env --ignore-signal=HUP bash $argv[1]; echo "[exit $status]"; exec fish' %s1'';
            orphan = true;
            desc = "Run in wezterm";
            for = "unix";
          }
        ];
      };
      open =
      {
        prepend_rules =
        [
          {
            # yazi drops the x- prefix: application/pie-executable
            mime = "application/{,x-}{executable,pie-executable}";
            use = [ "run" "reveal" ];
          }
          {
            url = "*.nix";
            use = "edit";
          }
          {
            url = "*.lua";
            use = "edit";
          }
          {
            url = "*.sh";
            use = [ "edit" "run-sh" ];
          }
          {
            url = "*.toml";
            use = "edit";
          }
          {
            url = "*.yaml";
            use = "edit";
          }
          {
            url = "*.yml";
            use = "edit";
          }
          {
            url = "*.json";
            use = "edit";
          }
          {
            url = "*.md";
            use = "edit";
          }
          {
            mime = "text/*";
            use = "edit";
          }
          {
            mime = "application/x-subrip";
            use = "edit";
          }
        ];
      };
      theme =
      {
        mgr =
        {
          cwd =
          {
            fg = p.accent;
          };
          hovered =
          {
            fg = p.background;
            bg = p.accent;
          };
          preview_hovered =
          {
            underline = true;
          };
          find_keyword =
          {
            fg = p.warning;
            italic = true;
          };
          find_position =
          {
            fg = p.error;
            italic = true;
          };
          marker_copied =
          {
            fg = p.success;
            bg = p.success;
          };
          marker_cut =
          {
            fg = p.error;
            bg = p.error;
          };
          marker_marked =
          {
            fg = p.warning;
            bg = p.warning;
          };
          marker_selected =
          {
            fg = p.accent;
            bg = p.accent;
          };
          tab_active =
          {
            fg = p.background;
            bg = p.accent;
          };
          tab_inactive =
          {
            fg = p.foreground;
            bg = p.surface;
          };
          border_style =
          {
            fg = p.muted;
          };
        };

        mode =
        {
          normal_main =
          {
            fg = p.background;
            bg = p.accent;
            bold = true;
          };
          select_main =
          {
            fg = p.background;
            bg = p.success;
            bold = true;
          };
          unset_main =
          {
            fg = p.background;
            bg = p.error;
            bold = true;
          };
        };

        git =
        {
          added.fg = p.success;
          staged.fg = p.success;
          unstaged.fg = p.warning;
          updated.fg = p.warning;
          untracked.fg = p.blue;
          deleted.fg = p.error;
          ignored.fg = p.muted;
        };

        status =
        {
          overall =
          {
            fg = p.foreground;
            bg = p.surface;
          };
        };

        which =
        {
          mask =
          {
            bg = p.background;
          };
          cand =
          {
            fg = p.blue;
          };
          rest =
          {
            fg = p.muted;
          };
          desc =
          {
            fg = p.accent;
          };
          separator = "  ";
        };

        confirm =
        {
          border =
          {
            fg = p.accent;
          };
          title =
          {
            fg = p.accent;
          };
          body =
          {
            fg = p.foreground;
          };
          list =
          {
            fg = p.foreground;
          };
          btn_yes =
          {
            fg = p.background;
            bg = p.success;
          };
          btn_no =
          {
            fg = p.background;
            bg = p.error;
          };
        };
      };
    };
  };
}
