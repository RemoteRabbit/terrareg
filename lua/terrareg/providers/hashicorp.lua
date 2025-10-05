--- HashiCorp provider for terrareg.nvim
-- @module terrareg.providers.hashicorp

local M = {}
local http = require("terrareg.http")
local parser = require("terrareg.parser")

-- HashiCorp provider configuration
M.config = {
  name = "hashicorp",
  display_name = "HashiCorp",
  base_url = "https://registry.terraform.io/providers/hashicorp",
  api_url = "https://registry.terraform.io/v1/providers/hashicorp",
}

-- HashiCorp services and their resources
M.services = {
  vault = {
    name = "vault",
    display_name = "Vault",
    description = "HashiCorp Vault provider for secrets management",
    resources = {
      {
        name = "vault_auth_backend",
        type = "resource",
        category = "Auth",
        description = "Manages a Vault auth backend",
      },
      {
        name = "vault_generic_secret",
        type = "resource",
        category = "Secrets",
        description = "Manages a generic secret in Vault",
      },
      {
        name = "vault_policy",
        type = "resource",
        category = "Policies",
        description = "Manages a Vault policy",
      },
      {
        name = "vault_mount",
        type = "resource",
        category = "Mounts",
        description = "Manages a Vault mount",
      },
      {
        name = "vault_database_secret_backend_connection",
        type = "resource",
        category = "Database",
        description = "Manages a database connection in Vault",
      },
      {
        name = "vault_database_secret_backend_role",
        type = "resource",
        category = "Database",
        description = "Manages a database role in Vault",
      },
      {
        name = "vault_pki_secret_backend",
        type = "resource",
        category = "PKI",
        description = "Manages a PKI secret backend in Vault",
      },
      {
        name = "vault_pki_secret_backend_root_cert",
        type = "resource",
        category = "PKI",
        description = "Manages a PKI root certificate",
      },
      {
        name = "vault_token",
        type = "resource",
        category = "Auth",
        description = "Manages a Vault token",
      },
      {
        name = "vault_namespace",
        type = "resource",
        category = "Enterprise",
        description = "Manages a Vault namespace",
      },
      -- Data sources
      {
        name = "vault_generic_secret",
        type = "data",
        category = "Secrets",
        description = "Reads a generic secret from Vault",
      },
      {
        name = "vault_policy_document",
        type = "data",
        category = "Policies",
        description = "Generates a Vault policy document",
      },
    },
  },
  consul = {
    name = "consul",
    display_name = "Consul",
    description = "HashiCorp Consul provider for service discovery and configuration",
    resources = {
      {
        name = "consul_service",
        type = "resource",
        category = "Services",
        description = "Manages a Consul service",
      },
      {
        name = "consul_node",
        type = "resource",
        category = "Nodes",
        description = "Manages a Consul node",
      },
      {
        name = "consul_key_prefix",
        type = "resource",
        category = "KV",
        description = "Manages a set of keys in Consul's KV store",
      },
      {
        name = "consul_keys",
        type = "resource",
        category = "KV",
        description = "Manages individual keys in Consul's KV store",
      },
      {
        name = "consul_agent_service",
        type = "resource",
        category = "Services",
        description = "Manages a service on the local Consul agent",
      },
      {
        name = "consul_intention",
        type = "resource",
        category = "Connect",
        description = "Manages a Consul Connect intention",
      },
      {
        name = "consul_config_entry",
        type = "resource",
        category = "Config",
        description = "Manages a Consul configuration entry",
      },
      {
        name = "consul_acl_policy",
        type = "resource",
        category = "ACL",
        description = "Manages a Consul ACL policy",
      },
      {
        name = "consul_acl_token",
        type = "resource",
        category = "ACL",
        description = "Manages a Consul ACL token",
      },
      {
        name = "consul_namespace",
        type = "resource",
        category = "Enterprise",
        description = "Manages a Consul namespace",
      },
      -- Data sources
      {
        name = "consul_services",
        type = "data",
        category = "Services",
        description = "Gets information about services in Consul",
      },
      {
        name = "consul_nodes",
        type = "data",
        category = "Nodes",
        description = "Gets information about nodes in Consul",
      },
      {
        name = "consul_keys",
        type = "data",
        category = "KV",
        description = "Reads keys from Consul's KV store",
      },
      {
        name = "consul_service",
        type = "data",
        category = "Services",
        description = "Gets information about a Consul service",
      },
    },
  },
  nomad = {
    name = "nomad",
    display_name = "Nomad",
    description = "HashiCorp Nomad provider for workload orchestration",
    resources = {
      {
        name = "nomad_job",
        type = "resource",
        category = "Jobs",
        description = "Manages a Nomad job",
      },
      {
        name = "nomad_namespace",
        type = "resource",
        category = "Namespaces",
        description = "Manages a Nomad namespace",
      },
      {
        name = "nomad_sentinel_policy",
        type = "resource",
        category = "Policies",
        description = "Manages a Nomad Sentinel policy",
      },
      {
        name = "nomad_acl_policy",
        type = "resource",
        category = "ACL",
        description = "Manages a Nomad ACL policy",
      },
      {
        name = "nomad_acl_token",
        type = "resource",
        category = "ACL",
        description = "Manages a Nomad ACL token",
      },
      {
        name = "nomad_quota_specification",
        type = "resource",
        category = "Quotas",
        description = "Manages a Nomad quota specification",
      },
      {
        name = "nomad_csi_volume",
        type = "resource",
        category = "Storage",
        description = "Manages a Nomad CSI volume",
      },
      {
        name = "nomad_external_volume",
        type = "resource",
        category = "Storage",
        description = "Manages a Nomad external volume",
      },
      {
        name = "nomad_variable",
        type = "resource",
        category = "Variables",
        description = "Manages a Nomad variable",
      },
      -- Data sources
      {
        name = "nomad_deployments",
        type = "data",
        category = "Jobs",
        description = "Gets information about Nomad deployments",
      },
      {
        name = "nomad_job",
        type = "data",
        category = "Jobs",
        description = "Gets information about a Nomad job",
      },
      {
        name = "nomad_namespaces",
        type = "data",
        category = "Namespaces",
        description = "Gets information about Nomad namespaces",
      },
      {
        name = "nomad_regions",
        type = "data",
        category = "Cluster",
        description = "Gets information about Nomad regions",
      },
    },
  },
}

--- Get all HashiCorp resources
-- @return table List of resources
function M.get_resources()
  local all_resources = {}

  for service_name, service in pairs(M.services) do
    for _, resource in ipairs(service.resources) do
      resource.service = service_name
      resource.provider = "hashicorp"
      table.insert(all_resources, resource)
    end
  end

  return all_resources
end

--- Search HashiCorp resources
-- @param query string Search query
-- @return table List of matching resources
function M.search_resources(query)
  local results = {}
  local lower_query = query:lower()

  for service_name, service in pairs(M.services) do
    for _, resource in ipairs(service.resources) do
      if
        resource.name:lower():find(lower_query, 1, true)
        or resource.description:lower():find(lower_query, 1, true)
        or resource.category:lower():find(lower_query, 1, true)
        or service_name:lower():find(lower_query, 1, true)
      then
        resource.service = service_name
        resource.provider = "hashicorp"
        table.insert(results, resource)
      end
    end
  end

  return results
end

--- Detect HashiCorp service from resource name
-- @param resource_name string Resource name
-- @return string|nil Service name
function M.detect_service(resource_name)
  for service_name, _ in pairs(M.services) do
    if resource_name:match("^" .. service_name .. "_") then
      return service_name
    end
  end
  return nil
end

--- Fetch documentation for a HashiCorp resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @param version string|nil Version
-- @param callback function Callback function
function M.fetch_documentation(resource_type, resource_name, version, callback)
  local service = M.detect_service(resource_name)
  if not service then
    callback(false, nil, "Unknown HashiCorp service for resource: " .. resource_name)
    return
  end

  local resource_path = resource_name:gsub("^" .. service .. "_", "")
  local doc_type = resource_type == "data" and "data-sources" or "resources"
  local provider_version = version or "latest"
  local url = string.format(
    "%s/%s/%s/docs/%s/%s",
    M.config.base_url,
    service,
    provider_version,
    doc_type,
    resource_path
  )

  http.fetch(url, function(success, content, error)
    if not success then
      callback(false, nil, error)
      return
    end

    -- Parse the documentation
    local doc_data = parser.parse_terraform_registry(content, {
      provider = "hashicorp/" .. service,
      resource_type = resource_type,
      resource_name = resource_name,
      url = url,
    })

    if not doc_data then
      callback(false, nil, "Failed to parse documentation")
      return
    end

    callback(true, doc_data, nil)
  end)
end

--- Check if resource exists
-- @param resource_name string Resource name
-- @return boolean True if resource exists
function M.has_resource(resource_name)
  local service = M.detect_service(resource_name)
  if not service then
    return false
  end

  local service_info = M.services[service]
  if not service_info then
    return false
  end

  for _, resource in ipairs(service_info.resources) do
    if resource.name == resource_name then
      return true
    end
  end

  return false
end

--- Get resource info
-- @param resource_name string Resource name
-- @return table|nil Resource info
function M.get_resource_info(resource_name)
  local service = M.detect_service(resource_name)
  if not service then
    return nil
  end

  local service_info = M.services[service]
  if not service_info then
    return nil
  end

  for _, resource in ipairs(service_info.resources) do
    if resource.name == resource_name then
      resource.service = service
      resource.provider = "hashicorp"
      return resource
    end
  end

  return nil
end

--- Get available HashiCorp services
-- @return table List of service names
function M.get_services()
  local services = {}
  for service_name, service_info in pairs(M.services) do
    table.insert(services, {
      name = service_name,
      display_name = service_info.display_name,
      description = service_info.description,
    })
  end
  table.sort(services, function(a, b)
    return a.name < b.name
  end)
  return services
end

--- Get resources by service
-- @param service_name string Service name
-- @return table List of resources for the service
function M.get_resources_by_service(service_name)
  local service_info = M.services[service_name]
  if not service_info then
    return {}
  end

  local results = {}
  for _, resource in ipairs(service_info.resources) do
    resource.service = service_name
    resource.provider = "hashicorp"
    table.insert(results, resource)
  end

  return results
end

--- Get resource categories
-- @return table List of categories
function M.get_categories()
  local categories = {}
  local seen = {}

  for _, service in pairs(M.services) do
    for _, resource in ipairs(service.resources) do
      if not seen[resource.category] then
        table.insert(categories, resource.category)
        seen[resource.category] = true
      end
    end
  end

  table.sort(categories)
  return categories
end

return M
