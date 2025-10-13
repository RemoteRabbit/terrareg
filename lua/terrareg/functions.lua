-- Registry building functions for terrareg.nvim
-- Handles fetching Terraform provider information from GitHub API
-- and building the local provider registry for fast access.
-- @module terrareg.functions

local M = {}

local curl = require("plenary.curl")
local Job = require("plenary.job")
local log = require("terrareg.log")
local filesystem = require("terrareg.filesystem")
local base_gh_url = "https://api.github.com/search/repositories?q=org:hashicorp+topic:terraform-provider&per_page=100"

-- Parse GitHub API Link header for pagination
-- Extracts the "next" URL from GitHub's Link header to support pagination
-- through large result sets.
-- @param link_header string The Link header from GitHub API response
-- @return string|nil The next page URL, or nil if no more pages
local function parse_link_header(link_header)
	if not link_header then
		return nil
	end

	local next_url = link_header:match('<([^>]+)>; rel="next"')
	return next_url
end

-- Recursively fetch all pages from GitHub API
-- Handles GitHub API pagination by following "next" links in the Link header.
-- Accumulates all repositories across pages and calls the callback when complete.
-- @param url string The API URL to fetch (may be initial URL or next page)
-- @param all_repos table Accumulator table for all repository data
-- @param callback function Function to call with complete results
local function fetch_all_pages(url, all_repos, callback)
	curl.get(url, {
		headers = {
			["Accept"] = "application/vnd.github+json",
			["User-agent"] = "chrome",
			["X-GitHub-Api-Version"] = "2022-11-28",
		},
		callback = function(response)
			local data = vim.json.decode(response.body)

			for _, item in ipairs(data.items or {}) do
				table.insert(all_repos, {
					name = item.name,
					url = item.url,
					html_url = item.html_url,
					description = item.description,
				})
			end

			local next_url = parse_link_header(response.headers.link)
			if next_url then
				log.info("Fetching next page: " .. #all_repos .. " providers so far")
				fetch_all_pages(next_url, all_repos, callback)
			else
				log.info("Registry build complete. Total providers: " .. #all_repos)
				callback(all_repos)
			end
		end,
		on_error = function(error)
			log.error(
				"Error when fetching providers from Github. Exit code(status): "
					.. error.exit
					.. "("
					.. error.status
					.. ")"
			)
		end,
	})
end

-- Build the local Terraform provider registry
-- Fetches all HashiCorp Terraform providers from GitHub API and builds
-- a local registry file for fast access. Creates the data directory if needed
-- and handles all pagination automatically.
-- @function registry_build
M.registry_build = function()
	local all_repos = {}
	fetch_all_pages(base_gh_url, all_repos, function(repos)
		if not DATA_DIR:exists() then
			log.debug("Docs directory does not exists, creating now...")
			DATA_DIR:mkdir()
		end
		local success = filesystem.write_registery(repos)
		if success then
			log.info("Registry has been written to disk.")
		else
			log.error("Failed to write registry to disk")
		end
	end)
end

-- Download versioned documentation from GitHub repos
-- Fetches the last 3 releases for each repo and downloads specific folder contents
-- using git sparse-checkout to minimize storage and API calls
-- @function download_versioned_docs
-- @param repo string GitHub repo in format "owner/repo"
-- @param folder_path string Path to folder within repo (e.g., "website/docs")
-- @param callback function optional callback when all downloads complete
local function download_versioned_docs(repo, folder_path, callback)
	local repo_name = repo:match("([^/]+)$")

	curl.get("https://api.github.com/repos/hashicorp/terraform-provider-" .. repo .. "/releases?per_page=3", {
		headers = {
			["Accept"] = "application/vnd.github+json",
			["User-Agent"] = "nvim-plugin",
		},
		callback = function(response)
			local releases = vim.json.decode(response.body)
			local total_downloads = 0
			local completed_downloads = 0
			local has_errors = false

			for i, release in ipairs(releases) do
				if i <= 3 then
					total_downloads = total_downloads + 1
				end
			end

			local function check_completion()
				completed_downloads = completed_downloads + 1
				if completed_downloads >= total_downloads then
					if callback then
						vim.schedule(function()
							callback(not has_errors)
						end)
					end
				end
			end

			for i, release in ipairs(releases) do
				if i <= 3 then
					local version = release.tag_name
					local version_dir = DOCS_DIR:joinpath(repo_name, version):__tostring()

					local job = Job:new({
						command = "bash",
						args = {
							"-c",
							string.format(
								[[
							set -e
							temp_dir=$(mktemp -d)
							cd "$temp_dir"
							git init
							git remote add origin https://github.com/hashicorp/terraform-provider-%s
							git config core.sparseCheckout true
							echo "%s/*" > .git/info/sparse-checkout
							git pull --depth=1 origin %s
							if [ ! -d "%s" ]; then
								echo "Warning: %s directory not found in repo"
								rm -rf "$temp_dir"
								exit 1
							fi
							mkdir -p "%s"
							cp -r %s/* "%s/"
							rm -rf "$temp_dir"
						]],
								repo,
								folder_path,
								version,
								folder_path,
								folder_path,
								version_dir,
								folder_path,
								version_dir
							),
						},
						on_exit = function(j, return_val)
							vim.schedule(function()
								if return_val ~= 0 then
									local stderr_lines = j:stderr_result()
									local actual_errors = {}
									for _, line in ipairs(stderr_lines) do
										if
											not line:match("^From https://")
											and not line:match("^%s*%*%s+tag%s+")
											and not line:match("^%s*%*%s+branch%s+")
											and not line:match("^%s+%->%s+FETCH_HEAD")
											and not line:match("^remote:")
											and line:trim() ~= ""
										then
											table.insert(actual_errors, line)
										end
									end

									if #actual_errors > 0 then
										local error_output = table.concat(actual_errors, "\n")
										log.error(
											"Failed to download " .. repo_name .. " " .. version .. ": " .. error_output
										)
									else
										log.debug(
											"Git command failed with non-zero exit but no actual errors: "
												.. repo_name
												.. " "
												.. version
										)
									end
									has_errors = true
								else
									log.info("Downloaded: " .. repo_name .. " " .. version)
								end
								check_completion()
							end)
						end,
						on_stderr = function(err, data) end,
					})

					job:start()
				end
			end

			if total_downloads == 0 then
				if callback then
					vim.schedule(function()
						callback(false)
					end)
				end
			end
		end,
		on_error = function(error)
			log.error("Error fetching releases for " .. repo .. ": " .. error.status)
			if callback then
				vim.schedule(function()
					callback(false)
				end)
			end
		end,
	})
end

-- Install provider
-- @function install_provider
-- @param provider string name of provider
-- @param callback function optional callback when installation completes
M.install_provider = function(provider, callback)
	local registry = filesystem.read_registery()
	if not registry then
		log.error("Registry index not found. Run :TerraregBuildReg")
		if callback then
			callback(false)
		end
		return false
	end

	local lockfile = filesystem.read_lockfile() or {}

	if lockfile[provider] then
		log.info("Provider " .. provider .. " already installed")
		if callback then
			callback(true)
		end
		return true
	end

	log.info("Installing provider: " .. provider)

	local paths_to_try = {}
	if provider == "random" then
		table.insert(paths_to_try, "docs")
	else
		table.insert(paths_to_try, "website/docs")
	end

	local function try_download_path(path_index)
		if path_index > #paths_to_try then
			log.error("Failed to download documentation for provider " .. provider)
			if callback then
				callback(false)
			end
			return
		end

		local path = paths_to_try[path_index]
		download_versioned_docs(provider, path, function(success)
			if success then
				lockfile[provider] = {
					installed_at = os.time(),
					versions = {},
				}

				local write_success = filesystem.write_lockfile(lockfile)
				if write_success then
					log.info("Provider " .. provider .. " installed successfully")
					if callback then
						callback(true)
					end
				else
					log.error("Failed to update lockfile for provider " .. provider)
					if callback then
						callback(false)
					end
				end
			else
				try_download_path(path_index + 1)
			end
		end)
	end

	try_download_path(1)

	return true
end

-- Download documentation for multiple repos with version history
-- Example usage for downloading last 3 versions of docs from terraform providers
-- @function ensure_installed
M.ensure_installed = function(providers)
	local registry = filesystem.read_registery()
	if not registry then
		log.error("Registry index not found. Run :TerraregBuildReg")
		return false
	end

	local lockfile = filesystem.read_lockfile() or {}
	local providers_to_install = {}

	for _, provider in ipairs(providers) do
		if not lockfile[provider] then
			table.insert(providers_to_install, provider)
		else
			log.debug("Provider " .. provider .. " already ensured")
		end
	end

	local function install_next(index)
		if index > #providers_to_install then
			if #providers_to_install > 0 then
				log.info("All " .. #providers_to_install .. " providers installation initiated")
			end
			return
		end

		local provider = providers_to_install[index]
		log.info("Ensuring provider " .. provider .. " is installed")

		M.install_provider(provider, function(success)
			if success then
				log.debug("Provider " .. provider .. " installation completed")
			else
				log.error("Provider " .. provider .. " installation failed")
			end

			vim.defer_fn(function()
				install_next(index + 1)
			end, 1000)
		end)
	end

	install_next(1)

	return #providers_to_install > 0
end

-- Remove provider and clean up documentation
-- @function remove_provider
-- @param provider string name of provider to remove
M.remove_provider = function(provider)
	local lockfile = filesystem.read_lockfile() or {}

	if not lockfile[provider] then
		log.info("Provider " .. provider .. " is not installed")
		return true
	end

	log.info("Removing provider: " .. provider)

	local docs_removed = filesystem.remove_docs(provider)
	if not docs_removed then
		log.error("Failed to remove documentation for " .. provider)
		return false
	end

	lockfile[provider] = nil
	local success = filesystem.write_lockfile(lockfile)

	if success then
		log.info("Provider " .. provider .. " removed successfully")
		return true
	else
		log.error("Failed to update lockfile after removing " .. provider)
		return false
	end
end

-- Update provider to latest versions (keep only last 3)
-- @function update_provider
-- @param provider string name of provider to update
-- @param callback function optional callback when update completes
M.update_provider = function(provider, callback)
	local lockfile = filesystem.read_lockfile() or {}

	if not lockfile[provider] then
		log.error("Provider " .. provider .. " is not installed. Use :TerraregInstall first")
		if callback then
			callback(false)
		end
		return false
	end

	log.info("Updating provider: " .. provider)

	curl.get("https://api.github.com/repos/hashicorp/terraform-provider-" .. provider .. "/releases?per_page=3", {
		headers = {
			["Accept"] = "application/vnd.github+json",
			["User-Agent"] = "nvim-plugin",
		},
		callback = function(response)
			local releases = vim.json.decode(response.body)
			local latest_versions = {}

			for i, release in ipairs(releases) do
				if i <= 3 then
					table.insert(latest_versions, release.tag_name)
				end
			end

			local provider_dir = DOCS_DIR:joinpath(provider)
			local installed_versions = {}

			if provider_dir:exists() then
				local ok, entries = pcall(function()
					return provider_dir:fs_scandir()
				end)
				if ok and entries then
					for name, type in entries do
						if type == "directory" then
							table.insert(installed_versions, name)
						end
					end
				end
			end

			local versions_to_remove = {}
			for _, installed in ipairs(installed_versions) do
				local is_latest = false
				for _, latest in ipairs(latest_versions) do
					if installed == latest then
						is_latest = true
						break
					end
				end
				if not is_latest then
					table.insert(versions_to_remove, installed)
				end
			end

			local versions_to_download = {}
			for _, latest in ipairs(latest_versions) do
				local is_installed = false
				for _, installed in ipairs(installed_versions) do
					if latest == installed then
						is_installed = true
						break
					end
				end
				if not is_installed then
					table.insert(versions_to_download, latest)
				end
			end

			for _, version in ipairs(versions_to_remove) do
				local version_dir = provider_dir:joinpath(version)
				local ok, err = pcall(function()
					version_dir:rm({ recursive = true })
				end)
				if ok then
					log.info("Removed old version: " .. provider .. " " .. version)
				else
					log.error("Failed to remove old version " .. provider .. " " .. version .. ": " .. tostring(err))
				end
			end

			if #versions_to_download == 0 then
				log.info("Provider " .. provider .. " is already up to date")
				if callback then
					vim.schedule(function()
						callback(true)
					end)
				end
				return
			end

			local downloads_completed = 0
			local downloads_failed = 0

			for _, version in ipairs(versions_to_download) do
				local version_dir = provider_dir:joinpath(version):__tostring()

				local job = Job:new({
					command = "bash",
					args = {
						"-c",
						string.format(
							[[
						set -e
						temp_dir=$(mktemp -d)
						cd "$temp_dir"
						git init
						git remote add origin https://github.com/hashicorp/terraform-provider-%s
						git config core.sparseCheckout true
						echo "website/docs/*" > .git/info/sparse-checkout
						git pull --depth=1 origin %s
						if [ ! -d "website/docs" ]; then
							echo "Warning: website/docs directory not found in repo"
							rm -rf "$temp_dir"
							exit 1
						fi
						mkdir -p "%s"
						cp -r website/docs/* "%s/"
						rm -rf "$temp_dir"
					]],
							provider,
							version,
							version_dir,
							version_dir
						),
					},
					on_exit = function(j, return_val)
						vim.schedule(function()
							if return_val ~= 0 then
								local stderr_lines = j:stderr_result()
								local actual_errors = {}
								for _, line in ipairs(stderr_lines) do
									if
										not line:match("^From https://")
										and not line:match("^%s*%*%s+tag%s+")
										and not line:match("^%s*%*%s+branch%s+")
										and not line:match("^%s+%->%s+FETCH_HEAD")
										and not line:match("^remote:")
										and line:trim() ~= ""
									then
										table.insert(actual_errors, line)
									end
								end

								if #actual_errors > 0 then
									local error_output = table.concat(actual_errors, "\n")
									log.error(
										"Failed to download " .. provider .. " " .. version .. ": " .. error_output
									)
								else
									log.debug(
										"Git command failed with non-zero exit but no actual errors: "
											.. provider
											.. " "
											.. version
									)
								end
								downloads_failed = downloads_failed + 1
							else
								log.info("Downloaded: " .. provider .. " " .. version)
							end

							downloads_completed = downloads_completed + 1

							if downloads_completed >= #versions_to_download then
								if downloads_failed == 0 then
									log.info("Provider " .. provider .. " updated successfully")
									if callback then
										callback(true)
									end
								else
									log.error(
										"Provider "
											.. provider
											.. " update completed with "
											.. downloads_failed
											.. " failures"
									)
									if callback then
										callback(false)
									end
								end
							end
						end)
					end,
				})

				job:start()
			end
		end,
		on_error = function(error)
			log.error("Error fetching releases for " .. provider .. ": " .. error.status)
			if callback then
				vim.schedule(function()
					callback(false)
				end)
			end
		end,
	})

	return true
end

return M
