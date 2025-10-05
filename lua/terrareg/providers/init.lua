--- Multi-provider support for terrareg.nvim
-- @module terrareg.providers

local M = {}

-- Registry of supported providers
M.providers = {}

--- Register a provider
-- @param name string Provider name (e.g., "aws", "azure", "gcp")
-- @param provider table Provider implementation
function M.register_provider(name, provider)
  M.providers[name] = provider
end

--- Get available providers
-- @return table List of provider names
function M.get_available_providers()
  local names = {}
  for name, _ in pairs(M.providers) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

--- Get provider by name
-- @param name string Provider name
-- @return table|nil Provider implementation
function M.get_provider(name)
  return M.providers[name]
end

--- Get all resources from all providers
-- @return table List of all resources across providers
function M.get_all_resources()
  local all_resources = {}

  for provider_name, provider in pairs(M.providers) do
    if provider.get_resources then
      local provider_resources = provider.get_resources()
      for _, resource in ipairs(provider_resources) do
        resource.provider = provider_name
        table.insert(all_resources, resource)
      end
    end
  end

  return all_resources
end

--- Search resources across all providers
-- @param query string Search query
-- @return table List of matching resources
function M.search_all_providers(query)
  local results = {}
  local lower_query = query:lower()

  for provider_name, provider in pairs(M.providers) do
    if provider.search_resources then
      local provider_results = provider.search_resources(query)
      for _, resource in ipairs(provider_results) do
        resource.provider = provider_name
        table.insert(results, resource)
      end
    end
  end

  return results
end

--- Fetch documentation from appropriate provider
-- @param provider_name string Provider name
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @param version string|nil Version
-- @param callback function Callback function
function M.fetch_documentation(provider_name, resource_type, resource_name, version, callback)
  local provider = M.providers[provider_name]
  if not provider then
    callback(false, nil, "Provider not found: " .. provider_name)
    return
  end

  if not provider.fetch_documentation then
    callback(false, nil, "Provider does not support documentation fetching: " .. provider_name)
    return
  end

  provider.fetch_documentation(resource_type, resource_name, version, callback)
end

--- Initialize all providers
function M.setup()
  -- Load and register AWS provider
  local aws_provider = require("terrareg.providers.aws")
  M.register_provider("aws", aws_provider)

  -- Load and register Azure provider
  local azure_provider = require("terrareg.providers.azure")
  M.register_provider("azure", azure_provider)

  -- Load and register GCP provider
  local gcp_provider = require("terrareg.providers.gcp")
  M.register_provider("gcp", gcp_provider)

  -- Load and register Kubernetes provider
  local k8s_provider = require("terrareg.providers.kubernetes")
  M.register_provider("kubernetes", k8s_provider)

  -- Load and register HashiCorp provider
  local hashicorp_provider = require("terrareg.providers.hashicorp")
  M.register_provider("hashicorp", hashicorp_provider)
end

return M
