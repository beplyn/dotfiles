{
  programs.nixvim.keymaps =
  [
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<cr>";
      options.desc = "Find files";
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>Telescope live_grep<cr>";
      options.desc = "Live grep";
    }
    {
      mode = "n";
      key = "<leader>fb";
      action = "<cmd>Telescope buffers<cr>";
      options.desc = "Find buffers";
    }
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "File explorer";
    }
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<cr>";
      options.desc = "Diagnostics";
    }
    {
      mode = "n";
      key = "<leader>cs";
      action = "<cmd>AerialToggle<cr>";
      options.desc = "Code symbols";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<cr>";
      options.desc = "Delete buffer";
    }
    {
      mode = "n";
      key = "<leader>w";
      action = "<cmd>write<cr>";
      options.desc = "Save buffer";
    }
    {
      mode = "n";
      key = "<leader>tc";
      action = "<cmd>TSContext toggle<cr>";
      options.desc = "Toggle Treesitter Context";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
      options =
      {
        noremap = true;
        silent = true;
        desc = "Indent right and preserve visual selection";
      };
    }
    {
      mode = "v";
      key = "<";
      action = "<gv";
      options =
      {
        noremap = true;
        silent = true;
        desc = "Indent left and preserve visual selection";
      };
    }
  ];
}
