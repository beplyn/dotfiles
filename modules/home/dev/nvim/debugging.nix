{
  programs.nixvim.plugins =
  {
    dap.enable = true;
    dap-ui.enable = true;
    overseer.enable = true;
  };

  programs.nixvim.keymaps =
  [
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
  ];
}
