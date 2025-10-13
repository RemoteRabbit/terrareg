-- Configuration module for terrareg.nvim
-- Handles plugin configuration setup and provides default values.
-- Sets up global paths for data storage and manages user options.
-- @module terrareg.config

local M = {}

local path = require("plenary.path")

-- Default configuration options
-- @field dir_path string Directory path for storing terrareg data
-- @field open_mode string How to open documentation windows ("split", "float", etc.)
-- @field float_win table Configuration for floating window display
-- @field ensure_installed table List of providers to ensure are installed
-- @table defaults
local defaults = {
	dir_path = vim.fn.stdpath("data") .. "/terrareg",
	open_mode = "split",
	float_win = {
		relative = "editor",
		height = "30",
		width = "120",
		border = "rounded",
	},
	-- TODO: Add ability to ensure specific versions are also installed
	ensure_installed = {},
}

-- Current configuration options
-- Populated by setup() function with user configuration merged with defaults
M.options = {}

-- Setup the plugin configuration
-- Merges user configuration with defaults and initializes global paths.
-- Creates global variables for data directories and file paths.
-- @param new_config table User configuration options to merge with defaults
-- @return table The final merged configuration
M.setup = function(new_config)
	M.options = vim.tbl_deep_extend("force", defaults, new_config or {})
	DATA_DIR = path:new(M.options.dir_path)
	DOCS_DIR = DATA_DIR:joinpath("docs")
	INDEX_PATH = DATA_DIR:joinpath("index.json")
	LOCK_PATH = DATA_DIR:joinpath("lock.json")
	REGISTRY_PATH = DATA_DIR:joinpath("registry.json")

	return defaults
end

return M
