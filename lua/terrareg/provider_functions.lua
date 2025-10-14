--- Provider-specific functions for terrareg.nvim
--- Handles provider documentation indexing and organization
--- @module terrareg.provider_functions

local M = {}

local log = require("terrareg.log")
local filesystem = require("terrareg.filesystem")
local scan = require("plenary.scandir")

--- Extract path sections from a file path
--- @param filepath string Full path to split into sections
--- @return string[] Table of path sections
local function extractPathSections(filepath)
	local sections = {}
	for section in string.gmatch(filepath, "[^/]+") do
		table.insert(sections, section)
	end
	return sections
end

--- Generate index for a provider's documentation
--- Scans provider documentation files and creates an index with metadata
--- @param provider string Provider name to index
--- @return table Index data structure with resource information
local function generate_index(provider)
	log.debug("Scanning" .. provider .. " provider files")
	local result = scan.scan_dir(DOCS_DIR:__tostring() .. "/" .. provider)
	local index = {}
	for _, file in ipairs(result) do
		local paths = extractPathSections(string.match(file, ".*(" .. provider .. ".*)"))
		local resource_type = ""

		if paths[3] == "index.md" then
			resource_type = "index"
		elseif paths[3] == "d" or paths[3] == "data" then
			resource_type = "data"
		elseif paths[3] == "r" or paths[3] == "resource" or paths[3] == "resources" then
			resource_type = "resource"
		elseif paths[3] == "actions" then
			resource_type = "action"
		elseif paths[3] == "ephemeral-resources" then
			resource_type = "ephemeral-resource"
		elseif paths[3] == "guide" then
			resource_type = "guide"
		elseif paths[3] == "list-resources" then
			resource_type = "list-resources"
		end

		local resource_name = paths[#paths]:gsub("%.html%.markdown", "")
		resource_name = resource_name:gsub("%.md$", "")
		local new_version = paths[2]

		local resource_found = false
		for _, entry in ipairs(index) do
			if entry.name == resource_name then
				local version_found = false
				for _, version in ipairs(entry.versions) do
					if version == new_version then
						version_found = true
						break
					end
				end
				if not version_found then
					table.insert(entry.versions, new_version)
				end
				resource_found = true
				break
			end
		end

		if not resource_found then
			local versions = { new_version }
			table.insert(index, {
				type = resource_type,
				name = resource_name,
				path = file,
				versions = versions,
			})
		end
	end
	return index
end

--- Write provider index to filesystem
--- Generates and writes an index file for the specified provider
--- @param provider string Provider name to generate index for
--- @return nil
M.write_index = function(provider)
	log.debug("Writing index to filesystem...")
	local index = generate_index(provider)
	local success = filesystem.write_index(index, provider)
	if success then
		log.info("Index for " .. provider .. " has been written to disk.")
	else
		log.error("Failed to write " .. provider .. " index to disk")
	end
end

return M
