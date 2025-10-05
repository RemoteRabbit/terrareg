--- Azure provider implementation for terrareg.nvim
-- @module terrareg.providers.azure

local M = {}

-- Provider metadata
M.name = "azure"
M.display_name = "Microsoft Azure"
M.icon = "🔷"
M.base_url = "https://registry.terraform.io/providers/hashicorp/azurerm"
M.docs_base_url =
  "https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs"

--- Common Azure resources
M.resources = {
  -- Compute
  {
    name = "azurerm_virtual_machine",
    type = "resource",
    category = "Compute",
    description = "Manages a Virtual Machine",
  },
  {
    name = "azurerm_linux_virtual_machine",
    type = "resource",
    category = "Compute",
    description = "Manages a Linux Virtual Machine",
  },
  {
    name = "azurerm_windows_virtual_machine",
    type = "resource",
    category = "Compute",
    description = "Manages a Windows Virtual Machine",
  },
  {
    name = "azurerm_virtual_machine_scale_set",
    type = "resource",
    category = "Compute",
    description = "Manages a Virtual Machine Scale Set",
  },

  -- Storage
  {
    name = "azurerm_storage_account",
    type = "resource",
    category = "Storage",
    description = "Manages a Storage Account",
  },
  {
    name = "azurerm_storage_container",
    type = "resource",
    category = "Storage",
    description = "Manages a Storage Container",
  },
  {
    name = "azurerm_storage_blob",
    type = "resource",
    category = "Storage",
    description = "Manages a Storage Blob",
  },

  -- Networking
  {
    name = "azurerm_virtual_network",
    type = "resource",
    category = "Network",
    description = "Manages a Virtual Network",
  },
  {
    name = "azurerm_subnet",
    type = "resource",
    category = "Network",
    description = "Manages a Subnet",
  },
  {
    name = "azurerm_network_security_group",
    type = "resource",
    category = "Network",
    description = "Manages a Network Security Group",
  },
  {
    name = "azurerm_public_ip",
    type = "resource",
    category = "Network",
    description = "Manages a Public IP",
  },
  {
    name = "azurerm_load_balancer",
    type = "resource",
    category = "Network",
    description = "Manages a Load Balancer",
  },

  -- Database
  {
    name = "azurerm_mssql_server",
    type = "resource",
    category = "Database",
    description = "Manages a Microsoft SQL Server",
  },
  {
    name = "azurerm_mssql_database",
    type = "resource",
    category = "Database",
    description = "Manages a Microsoft SQL Database",
  },
  {
    name = "azurerm_cosmosdb_account",
    type = "resource",
    category = "Database",
    description = "Manages a CosmosDB Account",
  },

  -- App Service
  {
    name = "azurerm_app_service_plan",
    type = "resource",
    category = "App Service",
    description = "Manages an App Service Plan",
  },
  {
    name = "azurerm_app_service",
    type = "resource",
    category = "App Service",
    description = "Manages an App Service",
  },
  {
    name = "azurerm_function_app",
    type = "resource",
    category = "App Service",
    description = "Manages a Function App",
  },

  -- Data Sources
  {
    name = "azurerm_client_config",
    type = "data",
    category = "Core",
    description = "Gets information about the current client configuration",
  },
  {
    name = "azurerm_subscription",
    type = "data",
    category = "Core",
    description = "Gets information about the current subscription",
  },
  {
    name = "azurerm_resource_group",
    type = "data",
    category = "Core",
    description = "Gets information about a Resource Group",
  },
  {
    name = "azurerm_virtual_network",
    type = "data",
    category = "Network",
    description = "Gets information about a Virtual Network",
  },
  {
    name = "azurerm_subnet",
    type = "data",
    category = "Network",
    description = "Gets information about a Subnet",
  },
}

--- Get all Azure resources
-- @return table List of Azure resources
function M.get_resources()
  return M.resources
end

--- Search Azure resources
-- @param query string Search query
-- @return table List of matching resources
function M.search_resources(query)
  local results = {}
  local lower_query = query:lower()

  for _, resource in ipairs(M.resources) do
    if
      resource.name:lower():find(lower_query, 1, true)
      or resource.description:lower():find(lower_query, 1, true)
      or resource.category:lower():find(lower_query, 1, true)
    then
      table.insert(results, resource)
    end
  end

  return results
end

--- Get documentation URL for Azure resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @param version string|nil Version
-- @return string Documentation URL
function M.get_documentation_url(resource_type, resource_name, version)
  version = version or "latest"
  local base_url = M.base_url .. "/" .. version .. "/docs"

  if resource_type == "resource" then
    return base_url .. "/resources/" .. resource_name
  elseif resource_type == "data" then
    return base_url .. "/data-sources/" .. resource_name
  else
    error("Invalid resource type. Use 'resource' or 'data'")
  end
end

--- Get alternative documentation URL (GitHub)
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @return string GitHub documentation URL
function M.get_alternative_url(resource_type, resource_name)
  if resource_type == "resource" then
    return M.docs_base_url .. "/r/" .. resource_name .. ".html.markdown"
  elseif resource_type == "data" then
    return M.docs_base_url .. "/d/" .. resource_name .. ".html.markdown"
  else
    error("Invalid resource type. Use 'resource' or 'data'")
  end
end

--- Fetch documentation for Azure resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @param version string|nil Version
-- @param callback function Callback function
function M.fetch_documentation(resource_type, resource_name, version, callback)
  local http = require("terrareg.http")
  local parser = require("terrareg.parser")

  local registry_url = M.get_documentation_url(resource_type, resource_name, version)
  local github_url = M.get_alternative_url(resource_type, resource_name)

  -- Try registry first
  http.get(registry_url, function(success, response, error)
    if success and response.body:match("Argument Reference") then
      local doc_data = {
        source = "registry",
        url = registry_url,
        title = resource_name,
        description = parser.extract_description(response.body),
        arguments = parser.extract_arguments(response.body),
        examples = parser.extract_examples(response.body),
      }
      callback(true, doc_data, nil)
    else
      -- Fallback to GitHub
      http.get(github_url, function(alt_success, alt_response, alt_error)
        if alt_success then
          local doc_data = {
            source = "github",
            url = github_url,
            title = resource_name .. " (GitHub)",
            description = parser.extract_description(alt_response.body),
            arguments = parser.extract_arguments(alt_response.body),
            examples = parser.extract_examples(alt_response.body),
          }
          callback(true, doc_data, nil)
        else
          callback(
            false,
            nil,
            "Failed to fetch from both registry and GitHub: " .. (alt_error or "unknown error")
          )
        end
      end)
    end
  end)
end

--- Get popular resources for prefetching
-- @return table List of popular resource identifiers
function M.get_popular_resources()
  return {
    { "resource", "azurerm_resource_group" },
    { "resource", "azurerm_virtual_network" },
    { "resource", "azurerm_subnet" },
    { "resource", "azurerm_linux_virtual_machine" },
    { "resource", "azurerm_storage_account" },
    { "data", "azurerm_client_config" },
    { "data", "azurerm_subscription" },
  }
end

return M
