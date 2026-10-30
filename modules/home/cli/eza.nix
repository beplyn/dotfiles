{ config, ... }:

let
  p = config.themes.palette;
in

{
  programs.eza =
  {
    enable = true;
    enableFishIntegration = true;
    icons = "auto";
    git = true;
    colors = "auto";
    extraOptions =
    [
      "--group-directories-first"
      "--header"
    ];

    theme =
    {
      colourful = true;

      filekinds =
      {
        normal =
        {
          foreground = p.subtext;
        };
        directory =
        {
          foreground = p.blue;
        };
        symlink =
        {
          foreground = p.cyan;
        };
        pipe =
        {
          foreground = p.muted;
        };
        block_device =
        {
          foreground = p.red;
        };
        char_device =
        {
          foreground = p.red;
        };
        socket =
        {
          foreground = p.surface;
        };
        special =
        {
          foreground = p.purple;
        };
        executable =
        {
          foreground = p.green;
        };
        mount_point =
        {
          foreground = p.blue;
        };
      };

      perms =
      {
        user_read =
        {
          foreground = p.foreground;
        };
        user_write =
        {
          foreground = p.yellow;
        };
        user_execute_file =
        {
          foreground = p.green;
        };
        user_execute_other =
        {
          foreground = p.green;
        };
        group_read =
        {
          foreground = p.subtext;
        };
        group_write =
        {
          foreground = p.yellow;
        };
        group_execute =
        {
          foreground = p.green;
        };
        other_read =
        {
          foreground = p.subtext;
        };
        other_write =
        {
          foreground = p.yellow;
        };
        other_execute =
        {
          foreground = p.green;
        };
        special_user_file =
        {
          foreground = p.purple;
        };
        special_other =
        {
          foreground = p.surface;
        };
        attribute =
        {
          foreground = p.subtext;
        };
      };

      size =
      {
        major =
        {
          foreground = p.subtext;
        };
        minor =
        {
          foreground = p.cyan;
        };
        number_byte =
        {
          foreground = p.foreground;
        };
        number_kilo =
        {
          foreground = p.subtext;
        };
        number_mega =
        {
          foreground = p.blue;
        };
        number_giga =
        {
          foreground = p.purple;
        };
        number_huge =
        {
          foreground = p.purple;
        };
        unit_byte =
        {
          foreground = p.subtext;
        };
        unit_kilo =
        {
          foreground = p.blue;
        };
        unit_mega =
        {
          foreground = p.purple;
        };
        unit_giga =
        {
          foreground = p.purple;
        };
        unit_huge =
        {
          foreground = p.blue;
        };
      };

      users =
      {
        user_you =
        {
          foreground = p.foreground;
        };
        user_root =
        {
          foreground = p.red;
        };
        user_other =
        {
          foreground = p.purple;
        };
        group_yours =
        {
          foreground = p.subtext;
        };
        group_other =
        {
          foreground = p.muted;
        };
        group_root =
        {
          foreground = p.red;
        };
      };

      links =
      {
        normal =
        {
          foreground = p.cyan;
        };
        multi_link_file =
        {
          foreground = p.blue;
        };
      };

      git =
      {
        new =
        {
          foreground = p.green;
        };
        modified =
        {
          foreground = p.yellow;
        };
        deleted =
        {
          foreground = p.red;
        };
        renamed =
        {
          foreground = p.cyan;
        };
        typechange =
        {
          foreground = p.purple;
        };
        ignored =
        {
          foreground = p.muted;
        };
        conflicted =
        {
          foreground = p.red;
        };
      };

      git_repo =
      {
        branch_main =
        {
          foreground = p.foreground;
        };
        branch_other =
        {
          foreground = p.purple;
        };
        git_clean =
        {
          foreground = p.green;
        };
        git_dirty =
        {
          foreground = p.red;
        };
      };

      security_context =
      {
        colon =
        {
          foreground = p.muted;
        };
        user =
        {
          foreground = p.subtext;
        };
        role =
        {
          foreground = p.purple;
        };
        typ =
        {
          foreground = p.surface;
        };
        range =
        {
          foreground = p.purple;
        };
      };

      file_type =
      {
        image =
        {
          foreground = p.yellow;
        };
        video =
        {
          foreground = p.red;
        };
        music =
        {
          foreground = p.green;
        };
        lossless =
        {
          foreground = p.cyan;
        };
        crypto =
        {
          foreground = p.surface;
        };
        document =
        {
          foreground = p.foreground;
        };
        compressed =
        {
          foreground = p.purple;
        };
        temp =
        {
          foreground = p.red;
        };
        compiled =
        {
          foreground = p.blue;
        };
        build =
        {
          foreground = p.surface;
        };
        source =
        {
          foreground = p.blue;
        };
      };

      punctuation =
      {
        foreground = p.muted;
      };
      date =
      {
        foreground = p.yellow;
      };
      inode =
      {
        foreground = p.subtext;
      };
      blocks =
      {
        foreground = p.subtext;
      };
      header =
      {
        foreground = p.foreground;
      };
      octal =
      {
        foreground = p.cyan;
      };
      flags =
      {
        foreground = p.purple;
      };

      symlink_path =
      {
        foreground = p.cyan;
      };
      control_char =
      {
        foreground = p.blue;
      };
      broken_symlink =
      {
        foreground = p.red;
      };
      broken_path_overlay =
      {
        foreground = p.surface;
      };
    };
  };
}
