--- Kubernetes provider for terrareg.nvim
-- @module terrareg.providers.kubernetes

local M = {}
local http = require("terrareg.http")
local parser = require("terrareg.parser")

-- Kubernetes provider configuration
M.config = {
  name = "kubernetes",
  display_name = "Kubernetes",
  base_url = "https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs",
  api_url = "https://registry.terraform.io/v1/providers/hashicorp/kubernetes",
  prefix = "kubernetes_",
}

-- Common Kubernetes resources
M.resources = {
  -- Core resources
  {
    name = "kubernetes_namespace",
    type = "resource",
    category = "Core",
    description = "Manages a Kubernetes Namespace",
  },
  {
    name = "kubernetes_pod",
    type = "resource",
    category = "Workloads",
    description = "Manages a Kubernetes Pod",
  },
  {
    name = "kubernetes_deployment",
    type = "resource",
    category = "Workloads",
    description = "Manages a Kubernetes Deployment",
  },
  {
    name = "kubernetes_service",
    type = "resource",
    category = "Services",
    description = "Manages a Kubernetes Service",
  },
  {
    name = "kubernetes_config_map",
    type = "resource",
    category = "Config",
    description = "Manages a Kubernetes ConfigMap",
  },
  {
    name = "kubernetes_secret",
    type = "resource",
    category = "Config",
    description = "Manages a Kubernetes Secret",
  },
  {
    name = "kubernetes_persistent_volume",
    type = "resource",
    category = "Storage",
    description = "Manages a Kubernetes PersistentVolume",
  },
  {
    name = "kubernetes_persistent_volume_claim",
    type = "resource",
    category = "Storage",
    description = "Manages a Kubernetes PersistentVolumeClaim",
  },
  {
    name = "kubernetes_ingress",
    type = "resource",
    category = "Networking",
    description = "Manages a Kubernetes Ingress",
  },
  {
    name = "kubernetes_network_policy",
    type = "resource",
    category = "Networking",
    description = "Manages a Kubernetes NetworkPolicy",
  },
  {
    name = "kubernetes_service_account",
    type = "resource",
    category = "Auth",
    description = "Manages a Kubernetes ServiceAccount",
  },
  {
    name = "kubernetes_role",
    type = "resource",
    category = "Auth",
    description = "Manages a Kubernetes Role",
  },
  {
    name = "kubernetes_role_binding",
    type = "resource",
    category = "Auth",
    description = "Manages a Kubernetes RoleBinding",
  },
  {
    name = "kubernetes_cluster_role",
    type = "resource",
    category = "Auth",
    description = "Manages a Kubernetes ClusterRole",
  },
  {
    name = "kubernetes_cluster_role_binding",
    type = "resource",
    category = "Auth",
    description = "Manages a Kubernetes ClusterRoleBinding",
  },

  -- Data sources
  {
    name = "kubernetes_namespace",
    type = "data",
    category = "Core",
    description = "Data source for Kubernetes Namespace",
  },
  {
    name = "kubernetes_service",
    type = "data",
    category = "Services",
    description = "Data source for Kubernetes Service",
  },
  {
    name = "kubernetes_config_map",
    type = "data",
    category = "Config",
    description = "Data source for Kubernetes ConfigMap",
  },
  {
    name = "kubernetes_secret",
    type = "data",
    category = "Config",
    description = "Data source for Kubernetes Secret",
  },
  {
    name = "kubernetes_persistent_volume_claim",
    type = "data",
    category = "Storage",
    description = "Data source for Kubernetes PersistentVolumeClaim",
  },
  {
    name = "kubernetes_service_account",
    type = "data",
    category = "Auth",
    description = "Data source for Kubernetes ServiceAccount",
  },
}

--- Get all Kubernetes resources
-- @return table List of resources
function M.get_resources()
  return M.resources
end

--- Search Kubernetes resources
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

--- Fetch documentation for a Kubernetes resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @param version string|nil Version (ignored for Kubernetes)
-- @param callback function Callback function
function M.fetch_documentation(resource_type, resource_name, version, callback)
  if not resource_name:match("^kubernetes_") then
    callback(false, nil, "Not a Kubernetes resource: " .. resource_name)
    return
  end

  local resource_path = resource_name:gsub("^kubernetes_", "")
  local doc_type = resource_type == "data" and "data-sources" or "resources"
  local url = string.format("%s/%s/%s", M.config.base_url, doc_type, resource_path)

  http.fetch(url, function(success, content, error)
    if not success then
      callback(false, nil, error)
      return
    end

    -- Parse the documentation
    local doc_data = parser.parse_terraform_registry(content, {
      provider = "kubernetes",
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
  for _, resource in ipairs(M.resources) do
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
  for _, resource in ipairs(M.resources) do
    if resource.name == resource_name then
      return resource
    end
  end
  return nil
end

--- Get resource categories
-- @return table List of categories
function M.get_categories()
  local categories = {}
  local seen = {}

  for _, resource in ipairs(M.resources) do
    if not seen[resource.category] then
      table.insert(categories, resource.category)
      seen[resource.category] = true
    end
  end

  table.sort(categories)
  return categories
end

--- Get resources by category
-- @param category string Category name
-- @return table List of resources in category
function M.get_resources_by_category(category)
  local results = {}

  for _, resource in ipairs(M.resources) do
    if resource.category == category then
      table.insert(results, resource)
    end
  end

  return results
end

return M
