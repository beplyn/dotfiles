{ config, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
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
          foreground = c.base04;
        };
        directory =
        {
          foreground = c.base0D;
        };
        symlink =
        {
          foreground = c.base0C;
        };
        pipe =
        {
          foreground = c.base03;
        };
        block_device =
        {
          foreground = c.base08;
        };
        char_device =
        {
          foreground = c.base08;
        };
        socket =
        {
          foreground = c.base02;
        };
        special =
        {
          foreground = c.base0E;
        };
        executable =
        {
          foreground = c.base0B;
        };
        mount_point =
        {
          foreground = c.base0D;
        };
      };

      perms =
      {
        user_read =
        {
          foreground = c.base05;
        };
        user_write =
        {
          foreground = c.base0A;
        };
        user_execute_file =
        {
          foreground = c.base0B;
        };
        user_execute_other =
        {
          foreground = c.base0B;
        };
        group_read =
        {
          foreground = c.base04;
        };
        group_write =
        {
          foreground = c.base0A;
        };
        group_execute =
        {
          foreground = c.base0B;
        };
        other_read =
        {
          foreground = c.base04;
        };
        other_write =
        {
          foreground = c.base0A;
        };
        other_execute =
        {
          foreground = c.base0B;
        };
        special_user_file =
        {
          foreground = c.base0E;
        };
        special_other =
        {
          foreground = c.base02;
        };
        attribute =
        {
          foreground = c.base04;
        };
      };

      size =
      {
        major =
        {
          foreground = c.base04;
        };
        minor =
        {
          foreground = c.base0C;
        };
        number_byte =
        {
          foreground = c.base05;
        };
        number_kilo =
        {
          foreground = c.base04;
        };
        number_mega =
        {
          foreground = c.base0D;
        };
        number_giga =
        {
          foreground = c.base0E;
        };
        number_huge =
        {
          foreground = c.base0E;
        };
        unit_byte =
        {
          foreground = c.base04;
        };
        unit_kilo =
        {
          foreground = c.base0D;
        };
        unit_mega =
        {
          foreground = c.base0E;
        };
        unit_giga =
        {
          foreground = c.base0E;
        };
        unit_huge =
        {
          foreground = c.base0D;
        };
      };

      users =
      {
        user_you =
        {
          foreground = c.base05;
        };
        user_root =
        {
          foreground = c.base08;
        };
        user_other =
        {
          foreground = c.base0E;
        };
        group_yours =
        {
          foreground = c.base04;
        };
        group_other =
        {
          foreground = c.base03;
        };
        group_root =
        {
          foreground = c.base08;
        };
      };

      links =
      {
        normal =
        {
          foreground = c.base0C;
        };
        multi_link_file =
        {
          foreground = c.base0D;
        };
      };

      git =
      {
        new =
        {
          foreground = c.base0B;
        };
        modified =
        {
          foreground = c.base0A;
        };
        deleted =
        {
          foreground = c.base08;
        };
        renamed =
        {
          foreground = c.base0C;
        };
        typechange =
        {
          foreground = c.base0E;
        };
        ignored =
        {
          foreground = c.base03;
        };
        conflicted =
        {
          foreground = c.base08;
        };
      };

      git_repo =
      {
        branch_main =
        {
          foreground = c.base05;
        };
        branch_other =
        {
          foreground = c.base0E;
        };
        git_clean =
        {
          foreground = c.base0B;
        };
        git_dirty =
        {
          foreground = c.base08;
        };
      };

      security_context =
      {
        colon =
        {
          foreground = c.base03;
        };
        user =
        {
          foreground = c.base04;
        };
        role =
        {
          foreground = c.base0E;
        };
        typ =
        {
          foreground = c.base02;
        };
        range =
        {
          foreground = c.base0E;
        };
      };

      file_type =
      {
        image =
        {
          foreground = c.base0A;
        };
        video =
        {
          foreground = c.base08;
        };
        music =
        {
          foreground = c.base0B;
        };
        lossless =
        {
          foreground = c.base0C;
        };
        crypto =
        {
          foreground = c.base02;
        };
        document =
        {
          foreground = c.base05;
        };
        compressed =
        {
          foreground = c.base0E;
        };
        temp =
        {
          foreground = c.base08;
        };
        compiled =
        {
          foreground = c.base0D;
        };
        build =
        {
          foreground = c.base02;
        };
        source =
        {
          foreground = c.base0D;
        };
      };

      punctuation =
      {
        foreground = c.base03;
      };
      date =
      {
        foreground = c.base0A;
      };
      inode =
      {
        foreground = c.base04;
      };
      blocks =
      {
        foreground = c.base04;
      };
      header =
      {
        foreground = c.base05;
      };
      octal =
      {
        foreground = c.base0C;
      };
      flags =
      {
        foreground = c.base0E;
      };

      symlink_path =
      {
        foreground = c.base0C;
      };
      control_char =
      {
        foreground = c.base0D;
      };
      broken_symlink =
      {
        foreground = c.base08;
      };
      broken_path_overlay =
      {
        foreground = c.base02;
      };
    };
  };
}
