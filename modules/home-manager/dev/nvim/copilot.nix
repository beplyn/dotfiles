{
  programs.nixvim.plugins = {
    copilot-lua = {
      enable = true;
      settings = {
        suggestion = {
          enabled = true;
          auto_trigger = true;
        };
        panel.enabled = false;
      };
    };
    copilot-cmp.enable = true;
  };
}
