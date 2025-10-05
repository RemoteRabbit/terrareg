--- terrareg.nvim - A Neovim plugin for [brief description]
-- @module terrareg
-- @author remoterabbit
-- @license GPL-3

local M = {}

--- Default configuration for terrareg
-- @field option1 boolean Enable/disable feature 1 (default: true)
-- @field option2 string Configuration string (default: "default")
-- @table default_config
M.config = {
  -- Default configuration options
  option1 = true,
  option2 = "default",
}

--- Setup function for the plugin
-- Initializes the plugin with user configuration
-- @tparam table|nil opts User configuration options to override defaults
-- @usage require('terrareg').setup({ option1 = false })
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Initialize plugin components here
  -- TODO: Add initialization logic
end

--- Get current configuration
-- @treturn table Current plugin configuration
function M.get_config()
  return M.config
end

return M
