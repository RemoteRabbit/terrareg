-- Snacks picker integration for terrareg.nvim
-- Provides picker-based interfaces for browsing and managing Terraform providers
-- @module terrareg.pickers

---@class terrareg.pickers
local M = {}

local filesystem = require("terrareg.filesystem")
local functions = require("terrareg.functions")
local log = require("terrareg.log")

---@class terrareg.pickers.ProviderItem
---@field text string Display name of the provider
---@field provider string Internal provider name
---@field installed_at? number Unix timestamp of installation
---@field versions? table List of installed versions
---@field description? string Provider description from GitHub
---@field url? string GitHub URL of the provider repository

---@class terrareg.pickers.Config
---@field enabled? boolean Whether pickers are enabled (default: true)
---@field docs_open_cmd? string How to open documentation ("edit", "vsplit", "split", "tabnew", "float") (default: "float")
---@field float_config? table Configuration for floating window when docs_open_cmd is "float"
---@field keep_float_buffers? boolean Whether to keep floating window buffers after closing (default: false)
---@field [string] any Additional Snacks picker configuration options

--- Initialize the picker system and verify Snacks.nvim availability
--- Sets up the internal snacks reference for use by picker functions.
--- @param opts terrareg.pickers.Config? Configuration options for pickers
--- @return nil
--- @usage
--- require('terrareg.pickers').setup({
---   enabled = true,
---   docs_open_cmd = "float", -- How to open docs: "float" (default), "edit", "vsplit", "split", "tabnew"
---   keep_float_buffers = false, -- Whether to keep buffers after closing float (default: false)
---   float_config = { -- Configuration for floating window (when docs_open_cmd is "float")
---     width = 0.8,
---     height = 0.8,
---     border = "rounded",
---   },
---   -- additional snacks picker options
--- })
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", {
		enabled = true,
		docs_open_cmd = "float",
		keep_float_buffers = false,
		float_config = {
			width = 0.8,
			height = 0.8,
			border = "rounded",
			title = "Terraform Provider Documentation",
		},
	}, opts)

	local ok, snacks = pcall(require, "snacks")
	if not ok or not snacks.picker then
		vim.notify("Snacks.nvim with picker is required for terrareg pickers", vim.log.levels.WARN)
		return
	end

	M.snacks = snacks
	log.debug("Terrareg pickers initialized with Snacks.nvim")
end

--- Retrieve installed Terraform providers from the lockfile
--- Reads the terrareg lockfile and transforms provider data into picker items.
--- Each item includes installation date and version information.
--- @return terrareg.pickers.ProviderItem[] List of installed providers with metadata
--- @private
local function get_installed_providers()
	local lockfile = filesystem.read_lockfile()
	if not lockfile then
		log.debug("No lockfile found, returning empty provider list")
		return {}
	end

	local providers = {}
	for provider, data in pairs(lockfile) do
		table.insert(providers, {
			text = provider,
			provider = provider,
			installed_at = data.installed_at,
			versions = data.versions or {},
		})
	end

	table.sort(providers, function(a, b)
		return a.provider < b.provider
	end)

	log.debug("Found " .. #providers .. " installed providers")
	return providers
end

--- Retrieve available Terraform providers from the registry
--- Reads the terrareg registry (built from GitHub API) and transforms repository
--- data into picker items with descriptions and URLs.
--- @return terrareg.pickers.ProviderItem[] List of available providers from registry
--- @private
local function get_available_providers()
	local registry = filesystem.read_registery()
	if not registry then
		log.debug("No registry found, returning empty provider list")
		return {}
	end

	local providers = {}
	for _, repo in ipairs(registry) do
		local provider_name = repo.name:match("^terraform%-provider%-(.+)$")
		if provider_name then
			table.insert(providers, {
				text = provider_name,
				provider = provider_name,
				description = repo.description,
				url = repo.html_url,
			})
		end
	end

	table.sort(providers, function(a, b)
		return a.provider < b.provider
	end)

	log.debug("Found " .. #providers .. " available providers in registry")
	return providers
end

--- Display a picker for browsing installed Terraform providers
--- Shows providers with installation dates and provides actions for management.
--- Includes key bindings for removing (<C-r>) and updating (<C-u>) providers.
--- Opens provider documentation directory when a provider is selected.
--- @param opts table? Additional Snacks picker configuration options to merge
--- @return nil
--- @usage
--- -- Basic usage
--- require('terrareg.pickers').installed_providers()
---
--- -- With custom options
--- require('terrareg.pickers').installed_providers({
---   layout = { preset = "ivy" }
--- })
function M.installed_providers(opts)
	if not M.snacks then
		vim.notify("Call require('terrareg.pickers').setup() first", vim.log.levels.ERROR)
		return
	end

	local items = get_installed_providers()

	if #items == 0 then
		vim.notify("No providers installed. Use :TerraregInstall <provider> to install providers", vim.log.levels.WARN)
		return
	end

	opts = vim.tbl_deep_extend("force", {
		items = items,
		title = "Installed Terraform Providers",
		format = function(item)
			local install_date = item.installed_at and os.date("%Y-%m-%d", item.installed_at) or "Unknown"
			return {
				{ item.text, "Special" },
				{ " (" .. install_date .. ")", "Comment" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				local provider_path = DOCS_DIR:joinpath(item.provider)
				if provider_path:exists() then
					open_docs(provider_path:__tostring(), item.provider)
				else
					vim.notify("Documentation directory not found for " .. item.provider, vim.log.levels.WARN)
				end
			end
		end,
		actions = {
			remove_provider = function(picker, item)
				if item then
					vim.notify("Removing provider: " .. item.provider, vim.log.levels.INFO)
					functions.remove_provider(item.provider)
					picker:find({ refresh = true })
				end
			end,
			update_provider = function(picker, item)
				if item then
					vim.notify("Updating provider: " .. item.provider, vim.log.levels.INFO)
					functions.update_provider(item.provider)
					picker:find({ refresh = true })
				end
			end,
		},
		win = {
			input = {
				keys = {
					["<c-r>"] = { "remove_provider", mode = { "n", "i" }, desc = "Remove selected provider" },
					["<c-u>"] = { "update_provider", mode = { "n", "i" }, desc = "Update selected provider to latest version" },
				},
			},
		},
	}, opts or {})

	M.snacks.picker.pick(opts)
end

--- Display a picker for browsing and installing available Terraform providers
--- Shows providers from the registry that are not currently installed.
--- Selecting a provider will initiate the installation process with progress feedback.
--- Requires the registry to be built first via :TerraregBuildReg.
--- @param opts table? Additional Snacks picker configuration options to merge
--- @return nil
--- @usage
--- -- Basic usage
--- require('terrareg.pickers').available_providers()
---
--- -- With custom layout
--- require('terrareg.pickers').available_providers({
---   layout = { preset = "telescope" }
--- })
function M.available_providers(opts)
	if not M.snacks then
		vim.notify("Call require('terrareg.pickers').setup() first", vim.log.levels.ERROR)
		return
	end

	local registry = filesystem.read_registery()
	if not registry then
		vim.notify("Registry not found. Run :TerraregBuildReg first", vim.log.levels.ERROR)
		return
	end

	local items = get_available_providers()
	local lockfile = filesystem.read_lockfile() or {}

	local available_items = {}
	for _, item in ipairs(items) do
		if not lockfile[item.provider] then
			table.insert(available_items, item)
		end
	end

	if #available_items == 0 then
		vim.notify("All available providers are already installed", vim.log.levels.INFO)
		return
	end

	opts = vim.tbl_deep_extend("force", {
		items = available_items,
		title = "Available Terraform Providers (" .. #available_items .. " available)",
		format = function(item)
			local description = item.description and string.sub(item.description, 1, 80) or ""
			if #description > 80 then
				description = description .. "..."
			end
			return {
				{ item.text, "Special" },
				{ description and (" - " .. description) or "", "Comment" },
			}
		end,
		confirm = function(picker, item)
			if item then
				picker:close()
				vim.notify("Installing provider: " .. item.provider, vim.log.levels.INFO)
				functions.install_provider(item.provider, function(success)
					if success then
						vim.notify("Provider " .. item.provider .. " installed successfully", vim.log.levels.INFO)
					else
						vim.notify("Failed to install provider " .. item.provider, vim.log.levels.ERROR)
					end
				end)
			end
		end,
	}, opts or {})

	M.snacks.picker.pick(opts)
end

--- Get the latest version for a provider
--- @param versions table List of version strings
--- @return string|nil Latest version or nil if no versions
--- @private
local function get_latest_version(versions)
	if not versions or #versions == 0 then
		return nil
	end
	-- Versions are stored in order from GitHub API (latest first)
	return versions[1]
end

--- Open documentation using the configured command
--- @param path string Absolute path to open
--- @param provider_name? string Optional provider name for floating window title
--- @private
local function open_docs(path, provider_name)
	local cmd = M.config and M.config.docs_open_cmd or "float"
	
	if cmd == "float" and M.snacks then
		-- Verify file exists
		if not vim.fn.filereadable(path) then
			vim.notify("File not found: " .. path, vim.log.levels.ERROR)
			return
		end
		
		-- Create a new buffer and load the file
		local buf = vim.api.nvim_create_buf(false, false)
		
		-- Set the buffer name to the file path
		vim.api.nvim_buf_set_name(buf, path)
		
		-- Read the file content into the buffer
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("silent! read " .. vim.fn.fnameescape(path))
			-- Remove the first empty line that 'read' command adds
			if vim.api.nvim_buf_line_count(buf) > 1 then
				vim.api.nvim_buf_set_lines(buf, 0, 1, false, {})
			end
		end)
		
		-- Set buffer options
		vim.bo[buf].readonly = true
		vim.bo[buf].modifiable = false
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].swapfile = false
		
		-- Set filetype for syntax highlighting
		local ft = vim.filetype.match({ filename = path })
		if ft then
			vim.bo[buf].filetype = ft
		end
		
		local float_config = vim.tbl_deep_extend("force", M.config.float_config or {}, {
			buf = buf,
		})
		
		-- Set dynamic title if provider name is provided
		if provider_name and not float_config.title then
			float_config.title = "Terraform Provider: " .. provider_name
		elseif provider_name then
			float_config.title = float_config.title .. " - " .. provider_name
		end
		
		-- Add buffer cleanup callback if not keeping buffers
		if not M.config.keep_float_buffers then
			float_config.on_close = function()
				-- Schedule buffer deletion to avoid timing issues
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(buf) then
						vim.api.nvim_buf_delete(buf, { force = true })
					end
				end)
			end
		end
		
		M.snacks.win(float_config)
	else
		vim.cmd(cmd .. " " .. path)
	end
end

--- Display a version picker for a specific provider
--- @param provider_item terrareg.pickers.ProviderItem Provider to show versions for
--- @private
local function show_version_picker(provider_item)
	if not provider_item.versions or #provider_item.versions == 0 then
		vim.notify("No versions available for " .. provider_item.provider, vim.log.levels.WARN)
		return
	end

	local version_items = {}
	for _, version in ipairs(provider_item.versions) do
		table.insert(version_items, {
			text = version,
			version = version,
			provider = provider_item.provider,
		})
	end

	M.snacks.picker.pick({
		items = version_items,
		title = "Select Version: " .. provider_item.provider,
		format = function(item)
			return {
				{ item.text, "Special" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				local version_path = DOCS_DIR:joinpath(item.provider, item.version)
				if version_path:exists() then
					open_docs(version_path:__tostring(), item.provider .. " " .. item.version)
				else
					vim.notify("Documentation not found for " .. item.provider .. " " .. item.version, vim.log.levels.WARN)
				end
			end
		end,
	})
end

--- Display a picker for browsing Terraform provider documentation
--- Shows installed providers and opens the latest version documentation by default.
--- Use <C-v> to select a different version.
--- Each provider's documentation is organized by version in separate directories.
--- Requires providers to be installed first via :TerraregInstall.
--- @param opts table? Additional Snacks picker configuration options to merge
--- @return nil
--- @usage
--- -- Basic usage
--- require('terrareg.pickers').provider_docs()
---
--- -- With custom explorer layout
--- require('terrareg.pickers').provider_docs({
---   layout = { preset = "sidebar" }
--- })
function M.provider_docs(opts)
	if not M.snacks then
		vim.notify("Call require('terrareg.pickers').setup() first", vim.log.levels.ERROR)
		return
	end

	local items = get_installed_providers()

	if #items == 0 then
		vim.notify("No providers installed. Use :TerraregInstall <provider> to install providers", vim.log.levels.WARN)
		return
	end

	opts = vim.tbl_deep_extend("force", {
		items = items,
		title = "Provider Documentation (" .. #items .. " providers)",
		format = function(item)
			local latest_version = get_latest_version(item.versions)
			local version_count = item.versions and #item.versions or 0
			local version_text = latest_version and (" - latest: " .. latest_version) or (" - " .. version_count .. " versions")
			return {
				{ item.text, "Special" },
				{ version_text, "Comment" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				local latest_version = get_latest_version(item.versions)
				if latest_version then
					local latest_path = DOCS_DIR:joinpath(item.provider, latest_version)
					if latest_path:exists() then
						log.debug("Opening latest documentation for provider: " .. item.provider .. " (" .. latest_version .. ")")
						open_docs(latest_path:__tostring(), item.provider .. " (latest: " .. latest_version .. ")")
					else
						vim.notify("Latest documentation not found for " .. item.provider, vim.log.levels.WARN)
						log.error("Latest documentation path does not exist: " .. latest_path:__tostring())
					end
				else
					vim.notify("No versions available for " .. item.provider, vim.log.levels.WARN)
				end
			end
		end,
		actions = {
			select_version = function(picker, item)
				if item then
					picker:close()
					show_version_picker(item)
				end
			end,
		},
		win = {
			input = {
				keys = {
					["<c-v>"] = { "select_version", mode = { "n", "i" }, desc = "Select different version" },
				},
			},
		},
	}, opts or {})

	M.snacks.picker.pick(opts)
end

--- List and reopen kept floating documentation buffers
--- Only works when keep_float_buffers is enabled
--- @param opts table? Additional Snacks picker configuration options to merge
--- @return nil
function M.doc_buffers(opts)
	if not M.snacks then
		vim.notify("Call require('terrareg.pickers').setup() first", vim.log.levels.ERROR)
		return
	end

	if not M.config.keep_float_buffers then
		vim.notify("keep_float_buffers is disabled. Enable it to use this feature.", vim.log.levels.WARN)
		return
	end

	-- Find all documentation buffers
	local doc_buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			-- Check if this looks like a terraform documentation buffer
			if name:match("/terrareg/docs/") and vim.bo[buf].readonly then
				local provider_info = name:match("/terrareg/docs/([^/]+)")
				if provider_info then
					table.insert(doc_buffers, {
						text = provider_info,
						buf = buf,
						path = name,
					})
				end
			end
		end
	end

	if #doc_buffers == 0 then
		vim.notify("No documentation buffers found", vim.log.levels.INFO)
		return
	end

	opts = vim.tbl_deep_extend("force", {
		items = doc_buffers,
		title = "Documentation Buffers (" .. #doc_buffers .. " buffers)",
		format = function(item)
			return {
				{ item.text, "Special" },
				{ " (buffer " .. item.buf .. ")", "Comment" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if item and vim.api.nvim_buf_is_valid(item.buf) then
				-- Reopen the buffer in a floating window
				local float_config = vim.tbl_deep_extend("force", M.config.float_config or {}, {
					buf = item.buf,
					title = "Terraform Provider: " .. item.text,
				})
				M.snacks.win(float_config)
			else
				vim.notify("Buffer no longer valid", vim.log.levels.WARN)
			end
		end,
		actions = {
			delete_buffer = function(picker, item)
				if item and vim.api.nvim_buf_is_valid(item.buf) then
					vim.api.nvim_buf_delete(item.buf, { force = true })
					vim.notify("Deleted buffer: " .. item.text, vim.log.levels.INFO)
					picker:find({ refresh = true })
				end
			end,
		},
		win = {
			input = {
				keys = {
					["<c-d>"] = { "delete_buffer", mode = { "n", "i" }, desc = "Delete selected buffer" },
				},
			},
		},
	}, opts or {})

	M.snacks.picker.pick(opts)
end

return M
