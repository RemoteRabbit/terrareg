-- Main module for terrareg.nvim
-- @module terrareg

local M = {}

local config = require("terrareg.config")
local log = require("terrareg.log")
local functions = require("terrareg.functions")

-- Setup function for terrareg plugin
-- @param opts table User configuration options
M.setup = function(opts)
	config.setup(opts)
	if next(config.options.ensure_installed) then
		vim.defer_fn(function()
			log.debug("Installing ensured providers")
			functions.ensure_installed(config.options.ensure_installed)
		end, 3000)
	end

	local cmd = vim.api.nvim_create_user_command

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
					-- Extract provider name from terraform-provider-xxx format
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
			log.error("Please specify a provider name. Usage: :TerraregUpdate <provider>")
			return
		end
		functions.update_provider(opts.args)
	end, {
		nargs = 1,
		desc = "Update a Terraform provider to latest versions (keep last 3)",
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
end

return M
