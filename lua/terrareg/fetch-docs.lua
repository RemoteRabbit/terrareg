--- Documentation fetcher for terrareg.nvim
--- Handles fetching documentation from GitHub for Terraform providers
--- @module terrareg.fetch-docs

local http = require("terrareg.http")
local parser = require("terrareg.parser")

local M = {}

--- Enable debug mode
--- @param enabled boolean Whether to enable debug mode
--- @return nil
function M.set_debug(enabled)
  vim.g.terrareg_debug = enabled
end

local gh_url =
  "https://raw.githubusercontent.com/hashicorp/terraform-provider-<PROVIDER>/<VERSION>/website/docs/<RESOURCE_TYPE>/<RESOURCE>"

local providers = {
  aws = "aws",
  azure = "azurerm",
  gcp = "google",
  hashicorp = "hcp",
}

--- Generate Github url for given vars
--- @param provider string "aws" or "azure" or "hashicorp" or "gcp"
--- @param resource_type string "resource" or "data"
--- @param resource_name string Name of resource
--- @param version string? Version
--- @return string url GitHub URL for the documentation
local function url_generation(provider, resource_type, resource_name, version)
  local url = gh_url

  -- Provider and Resource substitution
  for k, _ in pairs(providers) do
    if k == provider then
      url = url:gsub("<PROVIDER>", k)

      if resource_name:match("^" .. k .. "_") then
        resource_name = resource_name:gsub("^" .. k .. "_", "")
      end

      url = url:gsub("<RESOURCE>", resource_name)
    end
  end

  -- resource/data substitution
  if resource_type == "resource" then
    url = url:gsub("<RESOURCE_TYPE>", "r")
  elseif resource_type == "data" then
    url = url:gsub("<RESOURCE_TYPE>", "d")
  end

  -- Version substitution
  if version == "latest" or version == "" or version == nil then
    url = url:gsub("<VERSION>", "main")
  elseif version:match("^v") then
    version = version:gsub("^v", "")
    url = url:gsub("<VERSION>", version)
  else
    url = url:gsub("<VERSION>", version)
  end

  return url .. ".html.markdown"
end

--- Fetch documentation from Github
--- @param provider string Provider name (e.g., "aws")
--- @param resource_type string Type of resource ("resource" or "data")
--- @param resource_name string Name of the resource
--- @param version string? Version to fetch (defaults to "latest")
--- @param callback fun(success: boolean, docs_data: table?, error: string?): nil Callback function
--- @return nil
function M.fetch_docs(provider, resource_type, resource_name, version, callback)
  local url = url_generation(provider, resource_type, resource_name, version)
  http.get(url, function(success, response, error)
    if vim.g.terrareg_debug then
      print("GitHub response - Success: " .. tostring(success))
      if error then
        print("GitHub error: " .. error)
      end
    end

    if success and response then
      if vim.g.terrareg_debug then
        print("GitHub content length: " .. #response.body)
      end

      local doc_data = {
        source = "github",
        url = url,
        resource_type = resource_type,
        resource_name = resource_name,
        provider = provider,
        title = resource_name .. " (GitHub)",
        description = parser.extract_description(response.body),
        arguments = parser.extract_arguments(response.body),
        examples = parser.extract_examples(response.body),
      }
      callback(true, doc_data, nil)
    else
      error = error or "GitHub: unknown error"

      if vim.g.terrareg_debug then
        print("Failed to source: " .. error)
      end

      callback(false, nil, error)
    end
  end)
end

-- NOTE: Example call
-- M.fetch_docs("aws", "resource", "aws_s3_bucket", "latest", function(success, doc_data, error)
--   if success then
--     print("Title: ", doc_data.title)
--     print("Description: ", doc_data.description)
--   else
--     print("Error: ", error)
--   end
-- end)

return M
