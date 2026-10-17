{
  programs.nixvim.keymaps = [
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
      key = "<leader>tt";
      action = "<cmd>Neotest summary toggle<cr>";
      options.desc = "Test summary";
    }
    {
      mode = "n";
      key = "<leader>tr";
      action = "<cmd>Neotest run<cr>";
      options.desc = "Run nearest test";
    }
    {
      mode = "n";
      key = "<leader>td";
      action = "<cmd>Neotest run focused<cr>";
      options.desc = "Run focused test file";
    }
    {
      mode = "n";
      key = "<leader>db";
      action = "<cmd>DapToggleBreakpoint<cr>";
      options.desc = "Toggle breakpoint";
    }
    {
      mode = "n";
      key = "<leader>dc";
      action = "<cmd>DapContinue<cr>";
      options.desc = "Continue debugger";
    }
    {
      mode = "n";
      key = "<leader>do";
      action = "<cmd>DapStepOver<cr>";
      options.desc = "Step over";
    }
    {
      mode = "n";
      key = "<leader>di";
      action = "<cmd>DapStepInto<cr>";
      options.desc = "Step into";
    }
    {
      mode = "n";
      key = "<leader>oo";
      action = "<cmd>OverseerToggle<cr>";
      options.desc = "Task list";
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
      action = "<cmd>TSContextToggle<cr>";
      options.desc = "Toggle Treesitter Context";
    }
  ];
}
