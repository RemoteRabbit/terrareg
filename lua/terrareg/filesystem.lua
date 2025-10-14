--- Filesystem operations for terrareg.nvim
--- Handles reading and writing of registry files, index files, and lockfiles.
--- All operations include proper error handling and logging.
--- @module terrareg.filesystem

local M = {}
local log = require("terrareg.log")

--- Write registry data to file
--- Writes JSON-encoded registry data to the registry file with error handling.
--- @param registry table[] Registry data table to encode and write
--- @return boolean True if write succeeded, false on error
M.write_registery = function(registry)
	local ok, err = pcall(function()
		REGISTRY_PATH:write(vim.json.encode(registry), "w")
	end)
	if not ok then
		log.error("Failed to write registry file: " .. tostring(err))
		return false
	end
	return true
end

--- Write index data to file
--- Encodes and writes index table to the index file with error handling.
--- @param index table Index table containing provider index data
--- @param provider string Provider name
--- @return boolean True if write succeeded, false on error
M.write_index = function(index, provider)
	local ok, err = pcall(function()
		local index_file = DOCS_DIR:joinpath(provider, "index.json")
		index_file:write(vim.json.encode(index), "w")
	end)
	if not ok then
		log.error("Failed to write index file: " .. tostring(err))
		return false
	end
	return true
end

--- Write lockfile data to file
--- Encodes and writes lockfile table to the lockfile with error handling.
--- @param lockfile table<string, table> Lockfile table containing version lock information
--- @return boolean True if write succeeded, false on error
M.write_lockfile = function(lockfile)
	local ok, err = pcall(function()
		local encoded = vim.fn.json_encode(lockfile)
		LOCK_PATH:write({ encoded }, "w")
	end)
	if not ok then
		log.error("Failed to write lockfile: " .. tostring(err))
		return false
	end
	return true
end

--- Read registry data from file
--- Reads and decodes the registry file containing provider information.
--- @return table[]? Registry entries table, or nil if file doesn't exist or read fails
M.read_registery = function()
	if not REGISTRY_PATH:exists() then
		log.debug("Registry file does not exist")
		return
	end
	local ok, result = pcall(function()
		local buf = REGISTRY_PATH:read()
		return vim.fn.json_decode(buf)
	end)
	if not ok then
		log.error("Failed to read registry file: " .. tostring(result))
		return
	end
	return result
end

--- Read index data from file
--- Reads and decodes the index file containing provider index information.
--- @param provider string Provider name
--- @return table? Index table, or nil if file doesn't exist or read fails
M.read_index = function(provider)
	local index_file = DOCS_DIR:joinpath(provider, "index.json")
	if not index_file:exists() then
		log.debug("Index file does not exist for provider " .. provider)
		return
	end
	local ok, result = pcall(function()
		local buf = index_file:read()
		return vim.fn.json_decode(buf)
	end)
	if not ok then
		log.error("Failed to read index file for " .. provider .. ": " .. tostring(result))
		return
	end
	return result
end

--- Read lockfile data from file
--- Reads and decodes the lockfile containing version lock information.
--- @return table<string, table>? Lockfile table, or nil if file doesn't exist or read fails
M.read_lockfile = function()
	if not LOCK_PATH:exists() then
		log.debug("Lockfile does not exist")
		return
	end
	local ok, result = pcall(function()
		local buf = LOCK_PATH:read()
		return vim.fn.json_decode(buf)
	end)
	if not ok then
		log.error("Failed to read lockfile: " .. tostring(result))
		return
	end
	return result
end

--- Remove documentation directory for a provider
--- Recursively removes the documentation directory for the specified provider alias.
--- @param alias string The provider alias (directory name to remove)
--- @return boolean True if removal succeeded, false on error
M.remove_docs = function(alias)
	local ok, err = pcall(function()
		local doc_path = DOCS_DIR:joinpath(alias)
		doc_path:rm({ recursive = true })
	end)
	if not ok then
		log.error("Failed to remove docs for " .. alias .. ": " .. tostring(err))
		return false
	end
	log.debug("Removed docs for " .. alias)
	return true
end

return M
