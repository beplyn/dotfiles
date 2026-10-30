{
  config,
  ...
}:

let
  hostIcon =
    {
      anvil = "󰢛";
      beacon = "";
      compass = "󰆋";
      shulker = "";
    }
    .${config.networking.hostName};
in

{
  programs.starship =
  {
    enable = true;
    interactiveOnly = true;

    settings =
    {
      "$schema" = "https://starship.rs/config-schema.json";
      format = "$hostname$directory[$git_branch$git_status]()$nix_shell";
      right_format = "$cmd_duration$time";
      add_newline = true;
      palette = "theme";

      # the shared colour names, so styles read fg:accent, bg:surface
      palettes.theme = config.themes.palette;

      directory =
      {
        format = "[](fg:surface)[ $path ]($style)[](fg:surface) ";
        style = "bg:surface fg:blue";
        truncation_symbol = "󰝰 …/";
        home_symbol = "";
        read_only = " ";
        substitutions =
        {
          Documents = "󰈙";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      git_branch =
      {
        format = "[](fg:surface)[ $symbol $branch ]($style)[](fg:surface) ";
        style = "bg:surface fg:cyan";
        symbol = "";
      };

      git_status =
      {
        style = "bg:surface fg:red";
        format = "[](fg:surface)([$all_status$ahead_behind]($style))[](fg:surface) ";
        up_to_date = "[ ✔ ](bg:surface fg:green)";
        untracked = "[󱜺\\($count\\)](bg:surface fg:yellow)";
        stashed = "[\\$](bg:surface fg:accent)";
        modified = "[\\($count\\)](bg:surface fg:yellow)";
        renamed = "[󱟀\\($count\\)](bg:surface fg:accent)";
        deleted = "[\\($count\\)](bg:surface fg:red)";
        staged = "[\\($count\\)](bg:surface fg:green)";
        ahead = "[󰜷\\($count\\)](bg:surface fg:cyan)";
        diverged = "󰹺[\\[](bg:surface fg:accent)[⇡\\($ahead_count\\)](bg:surface fg:cyan)[⇣\\($behind_count\\)](bg:surface fg:red)[\\]](bg:surface fg:accent)";
        behind = "[󰜮\\($count\\)](bg:surface fg:red)";
      };

      nix_shell =
      {
        format = "[](fg:surface)[ $symbol$state ]($style)[](fg:surface) ";
        symbol = " ";
        style = "bg:surface fg:blue";
      };

      hostname =
      {
        format = "[](fg:surface)[ ${hostIcon} ]($style)[](fg:surface) ";
        ssh_only = false;
        style = "bg:surface fg:blue";
      };

      cmd_duration =
      {
        min_time = 1000;
        format = "[](fg:surface)[  $duration ]($style)[](fg:surface)";
        style = "bg:surface fg:yellow";
      };

      time =
      {
        disabled = false;
        format = " [](fg:surface)[ $time 󱑃 ]($style)[](fg:surface)";
        style = "bg:surface fg:accent";
        time_format = "%I:%M%P";
        use_12hr = true;
      };
    };
  };
}
