function(params, config)
  -- replaces lspconfig's hook, which only did this
  local settings = config.settings and config.settings["rust-analyzer"]
  if settings then
    params.initializationOptions = settings
  end
  -- no Cargo.toml above: rust-analyzer finds no workspace and completes
  -- nothing, so hand it the file itself as a detached crate
  if config.root_dir == nil then
    params.initializationOptions = vim.tbl_extend(
      "force",
      params.initializationOptions or {},
      { detachedFiles = { vim.api.nvim_buf_get_name(0) } }
    )
  end
end
