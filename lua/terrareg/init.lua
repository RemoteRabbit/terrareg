--- Main module for terrareg.nvim
--- Entry point for the plugin, handles setup and command registration
--- @module terrareg

local M = {}

local config = require("terrareg.config")
local log = require("terrareg.log")
local functions = require("terrareg.functions")

--- Setup function for terrareg plugin
--- Initializes configuration, creates user commands, and sets up pickers
--- @param opts terrareg.Config? User configuration options
--- @return nil
M.setup = function(opts)
	config.setup(opts)
	if next(config.options.ensure_installed) then
		vim.defer_fn(function()
			log.debug("Installing ensured providers")
			functions.ensure_installed(config.options.ensure_installed)
		end, 3000)
	end

	local cmd = vim.api.nvim_create_user_command

	local pickers
	local enable_pickers = true
	if opts and opts.pickers and opts.pickers.enabled == false then
		enable_pickers = false
	end

	if enable_pickers then
		local ok, picker_module = pcall(require, "terrareg.pickers")
		if ok then
			pickers = picker_module
			pickers.setup(opts and opts.pickers or {})
			log.debug("Terrareg pickers enabled")
		else
			log.debug("Terrareg pickers not available (Snacks.nvim not found)")
		end
	end

	cmd("TerraregBuildReg", functions.registry_build, {})

	cmd("TerraregInstall", function(opts)
		if not opts.args or opts.args == "" then
			log.error("Please specify a provider name. Usage: :TerraregInstall <provider>")
			return
		end
		functions.install_provider(opts.args)
	end, {
		nargs = 1,
		desc = "Install a Terraform provider and its documentation",
		complete = function()
			local filesystem = require("terrareg.filesystem")
			local registry = filesystem.read_registery()
			if registry then
				local providers = {}
				for _, provider in ipairs(registry) do
					local provider_name = provider.name:match("^terraform%-provider%-(.+)$")
					if provider_name then
						table.insert(providers, provider_name)
					end
				end
				return providers
			end
			return {}
		end,
	})
	cmd("TerraregRemove", function(opts)
		if not opts.args or opts.args == "" then
			log.error("Please specify a provider name. Usage: :TerraregRemove <provider>")
			return
		end
		functions.remove_provider(opts.args)
	end, {
		nargs = 1,
		desc = "Remove a Terraform provider and its documentation",
		complete = function()
			local filesystem = require("terrareg.filesystem")
			local lockfile = filesystem.read_lockfile()
			if lockfile then
				local providers = {}
				for provider, _ in pairs(lockfile) do
					table.insert(providers, provider)
				end
				return providers
			end
			return {}
		end,
	})

	cmd("TerraregUpdate", function(opts)
		if not opts.args or opts.args == "" then
			functions.update_all_providers()
		else
			functions.update_provider(opts.args)
		end
	end, {
		nargs = "?",
		desc = "Update Terraform provider(s) to latest versions (keep last 3). Usage: :TerraregUpdate [provider] (no args = update all)",
		complete = function()
			local filesystem = require("terrareg.filesystem")
			local lockfile = filesystem.read_lockfile()
			if lockfile then
				local providers = {}
				for provider, _ in pairs(lockfile) do
					table.insert(providers, provider)
				end
				return providers
			end
			return {}
		end,
	})

	if pickers then
		cmd("TerraregPickerInstalled", pickers.installed_providers, {
			desc = "Show picker for installed Terraform providers",
		})

		cmd("TerraregPickerAvailable", pickers.available_providers, {
			desc = "Show picker for available Terraform providers to install",
		})

		cmd("TerraregPickerDocs", pickers.provider_docs, {
			desc = "Show picker for provider documentation",
		})

		cmd("TerraregPickerDocBuffers", pickers.doc_buffers, {
			desc = "Show picker for kept documentation buffers",
		})
	end
end

--- Open picker for installed providers
--- @param opts table? Options to pass to the picker
--- @return nil
M.pick_installed_providers = function(opts)
	local pickers = require("terrareg.pickers")
	pickers.installed_providers(opts)
end

--- Open picker for available providers
--- @param opts table? Options to pass to the picker
--- @return nil
M.pick_available_providers = function(opts)
	local pickers = require("terrareg.pickers")
	pickers.available_providers(opts)
end

--- Open picker for provider documentation
--- @param opts table? Options to pass to the picker
--- @return nil
M.pick_provider_docs = function(opts)
	local pickers = require("terrareg.pickers")
	pickers.provider_docs(opts)
end

--- Open picker for documentation buffers
--- @param opts table? Options to pass to the picker
--- @return nil
M.pick_doc_buffers = function(opts)
	local pickers = require("terrareg.pickers")
	pickers.doc_buffers(opts)
end

return M
