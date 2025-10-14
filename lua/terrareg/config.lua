--- Configuration module for terrareg.nvim
--- Handles plugin configuration setup and provides default values.
--- Sets up global paths for data storage and manages user options.
--- @module terrareg.config

local M = {}

local path = require("plenary.path")

--- Default configuration options
--- @class terrareg.Config
--- @field dir_path string Directory path for storing terrareg data (default: vim.fn.stdpath("data") .. "/terrareg")
--- @field open_mode string How to open documentation windows ("split", "float", etc.) (default: "float")
--- @field float_win terrareg.FloatWinConfig Configuration for floating window display
--- @field ensure_installed string[] List of providers to ensure are installed (default: {})

--- Floating window configuration
--- @class terrareg.FloatWinConfig
--- @field relative string Window positioning ("editor", "win", "cursor")
--- @field height string|number Window height
--- @field width string|number Window width
--- @field border string Border style ("none", "single", "double", "rounded", "solid", "shadow")
local defaults = {
	dir_path = vim.fn.stdpath("data") .. "/terrareg",
	open_mode = "float",
	float_win = {
		relative = "editor",
		height = "30",
		width = "120",
		border = "rounded",
	},
	-- TODO: Add ability to ensure specific versions are also installed
	ensure_installed = {},
}

--- Current configuration options
--- Populated by setup() function with user configuration merged with defaults
--- @type terrareg.Config
M.options = {}

--- Setup the plugin configuration
--- Merges user configuration with defaults and initializes global paths.
--- Creates global variables for data directories and file paths.
--- @param new_config terrareg.Config? User configuration options to merge with defaults
--- @return terrareg.Config The final merged configuration
M.setup = function(new_config)
	M.options = vim.tbl_deep_extend("force", defaults, new_config or {})
	DATA_DIR = path:new(M.options.dir_path)
	DOCS_DIR = DATA_DIR:joinpath("docs")
	LOCK_PATH = DATA_DIR:joinpath("lock.json")
	REGISTRY_PATH = DATA_DIR:joinpath("registry.json")

	return defaults
end

return M
