--- terrareg.nvim - A Neovim plugin for [brief description]
-- @module terrareg
-- @author remoterabbit
-- @license GPL-3.0

local M = {}

--- Default configuration for terrareg
-- @table default_config
M.config = {
  option1 = true,
  option2 = "default",
  debug = false,
}

--- Setup function for the plugin
-- Initializes the plugin with user configuration
-- @param opts table|nil User configuration options to override defaults
-- @usage require('terrareg').setup({ option1 = false, debug = true })
function M.setup(opts)
  local vim = vim
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Initialize plugin components here
  -- TODO: Add initialization logic

  if M.config.debug then
    print("terrareg.nvim: Debug mode enabled")
  end
end

--- Get current configuration
-- @return table Current plugin configuration
function M.get_config()
  return M.config
end

return M
