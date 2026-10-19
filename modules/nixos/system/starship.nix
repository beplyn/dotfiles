{
  config,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
  hostIcon =
    {
      anvil = "󰢛";
      compass = "󰆋";
      shulker = "";
    }
    .${config.networking.hostName};
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
  programs.starship = {
    enable = true;
    interactiveOnly = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      format = "$hostname$directory[$git_branch$git_status]()$nix_shell";
      right_format = "$cmd_duration$time";
      add_newline = true;
      palette = "theme";

      palettes.theme = {
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

      directory = {
        format = "[](fg:surface1)[ $path ]($style)[](fg:surface1) ";
        style = "bg:surface1 fg:blue";
        truncation_symbol = "󰝰 …/";
        home_symbol = "";
        read_only = " ";
        substitutions = {
          Documents = "󰈙";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      git_branch = {
        format = "[](fg:surface1)[ $symbol $branch ]($style)[](fg:surface1) ";
        style = "bg:surface1 fg:teal";
        symbol = "";
      };

      git_status = {
        style = "bg:surface1 fg:red";
        format = "[](fg:surface1)([$all_status$ahead_behind]($style))[](fg:surface1) ";
        up_to_date = "[ ✔ ](bg:surface1 fg:green)";
        untracked = "[󱜺\\($count\\)](bg:surface1 fg:yellow)";
        stashed = "[\\$](bg:surface1 fg:mauve)";
        modified = "[\\($count\\)](bg:surface1 fg:yellow)";
        renamed = "[󱟀\\($count\\)](bg:surface1 fg:mauve)";
        deleted = "[\\($count\\)](bg:surface1 fg:red)";
        staged = "[\\($count\\)](bg:surface1 fg:green)";
        ahead = "[󰜷\\($count\\)](bg:surface1 fg:teal)";
        diverged = "󰹺[\\[](bg:surface1 fg:mauve)[⇡\\($ahead_count\\)](bg:surface1 fg:teal)[⇣\\($behind_count\\)](bg:surface1 fg:red)[\\]](bg:surface1 fg:mauve)";
        behind = "[󰜮\\($count\\)](bg:surface1 fg:red)";
      };

      nix_shell = {
        format = "[](fg:surface1)[ $symbol$state ]($style)[](fg:surface1) ";
        symbol = " ";
        style = "bg:surface1 fg:blue";
      };

      hostname = {
        format = "[](fg:surface1)[ ${hostIcon} ]($style)[](fg:surface1) ";
        ssh_only = false;
        style = "bg:surface1 fg:blue";
      };

      cmd_duration = {
        min_time = 1000;
        format = "[](fg:surface1)[  $duration ]($style)[](fg:surface1)";
        style = "bg:surface1 fg:yellow";
      };

      time = {
        disabled = false;
        format = " [](fg:surface1)[ $time 󱑃 ]($style)[](fg:surface1)";
        style = "bg:surface1 fg:mauve";
        time_format = "%I:%M%P";
        use_12hr = true;
      };
    };
  };
}
