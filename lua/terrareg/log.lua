-- Logging module for terrareg.nvim
-- Provides unified logging interface with both file logging and Neovim notifications.
-- Uses plenary.log for file output and vim.notify for user notifications.
-- @module terrareg.log

local M = {}

-- Configure plenary.log instance with terrareg-specific settings
-- Creates a single log file that gets overwritten
local log_path = vim.fn.stdpath("data") .. "/terrareg/terrareg.log"

-- Ensure log file exists by writing initial entry
local log_file = io.open(log_path, "w")
if log_file then
	log_file:write(string.format("[INFO][%s] terrareg.log: Plugin initialized\n", os.date("%Y-%m-%d %H:%M:%S")))
	log_file:close()
end

local log = require("plenary.log").new({
	plugin = "terrareg",
	use_console = false,
	outfile = log_path,
	fmt_msg = function(_, mode_name, src_path, src_line, message)
		local mode = mode_name:upper()
		local source = vim.fn.fnamemodify(src_path, ":t") .. ":" .. src_line
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")

		return string.format("[%s][%s] %s: %s", mode, timestamp, source, message)
	end,
}, false)

-- Wrapper for vim.notify that adds terrareg prefix and schedules safely
-- @param message string The message to display
-- @param level number Vim log level constant
local notify = vim.schedule_wrap(function(message, level)
	vim.notify("[Terrareg] " .. message, level)
end)

-- Log debug message
-- Outputs to both log file and Neovim notification system at DEBUG level.
-- Debug messages are typically hidden unless debug mode is enabled.
-- @param message string The debug message to log
M.debug = function(message)
	notify(message, vim.log.levels.DEBUG)
	log.debug(message)
end

-- Log informational message
-- Outputs to both log file and Neovim notification system at INFO level.
-- Info messages provide general status updates to the user.
-- @param message string The informational message to log
M.info = function(message)
	notify(message, vim.log.levels.INFO)
	log.info(message)
end

-- Log warning message
-- Outputs to both log file and Neovim notification system at WARN level.
-- Warning messages indicate potential issues that don't prevent operation.
-- @param message string The warning message to log
M.warn = function(message)
	notify(message, vim.log.levels.WARN)
	log.warn(message)
end

-- Log error message
-- Outputs to both log file and Neovim notification system at ERROR level.
-- Error messages indicate failures that may affect plugin functionality.
-- @param message string The error message to log
M.error = function(message)
	notify(message, vim.log.levels.ERROR)
	log.error(message)
end

return M
