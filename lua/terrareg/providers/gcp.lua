--- Google Cloud provider implementation for terrareg.nvim
-- @module terrareg.providers.gcp

local M = {}

-- Provider metadata
M.name = "gcp"
M.display_name = "Google Cloud Platform"
M.icon = "☁️"
M.base_url = "https://registry.terraform.io/providers/hashicorp/google"
M.docs_base_url =
  "https://raw.githubusercontent.com/hashicorp/terraform-provider-google/main/website/docs"

--- Common GCP resources
M.resources = {
  -- Compute
  {
    name = "google_compute_instance",
    type = "resource",
    category = "Compute",
    description = "Manages a Compute Engine instance",
  },
  {
    name = "google_compute_disk",
    type = "resource",
    category = "Compute",
    description = "Manages a persistent disk",
  },
  {
    name = "google_compute_network",
    type = "resource",
    category = "Compute",
    description = "Manages a VPC network",
  },
  {
    name = "google_compute_subnetwork",
    type = "resource",
    category = "Compute",
    description = "Manages a subnetwork",
  },
  {
    name = "google_compute_firewall",
    type = "resource",
    category = "Compute",
    description = "Manages a firewall rule",
  },
  {
    name = "google_compute_instance_group",
    type = "resource",
    category = "Compute",
    description = "Manages an Instance Group",
  },

  -- Storage
  {
    name = "google_storage_bucket",
    type = "resource",
    category = "Storage",
    description = "Creates a new bucket in Google Cloud Storage",
  },
  {
    name = "google_storage_bucket_object",
    type = "resource",
    category = "Storage",
    description = "Creates a new object inside a bucket",
  },

  -- Container
  {
    name = "google_container_cluster",
    type = "resource",
    category = "Container",
    description = "Manages a Google Kubernetes Engine cluster",
  },
  {
    name = "google_container_node_pool",
    type = "resource",
    category = "Container",
    description = "Manages a node pool in GKE",
  },

  -- Database
  {
    name = "google_sql_database_instance",
    type = "resource",
    category = "SQL",
    description = "Creates a new Cloud SQL instance",
  },
  {
    name = "google_sql_database",
    type = "resource",
    category = "SQL",
    description = "Creates a new database in Cloud SQL instance",
  },
  {
    name = "google_sql_user",
    type = "resource",
    category = "SQL",
    description = "Creates a new user in Cloud SQL instance",
  },

  -- IAM
  {
    name = "google_service_account",
    type = "resource",
    category = "IAM",
    description = "Creates and manages service accounts",
  },
  {
    name = "google_project_iam_binding",
    type = "resource",
    category = "IAM",
    description = "Manages IAM bindings on projects",
  },
  {
    name = "google_project_iam_member",
    type = "resource",
    category = "IAM",
    description = "Manages IAM members on projects",
  },

  -- Cloud Functions
  {
    name = "google_cloudfunctions_function",
    type = "resource",
    category = "Functions",
    description = "Creates a new Cloud Function",
  },
  {
    name = "google_cloudfunctions2_function",
    type = "resource",
    category = "Functions",
    description = "Creates a new Cloud Function (2nd gen)",
  },

  -- Data Sources
  {
    name = "google_project",
    type = "data",
    category = "Core",
    description = "Gets information about a project",
  },
  {
    name = "google_client_config",
    type = "data",
    category = "Core",
    description = "Gets information about the current client configuration",
  },
  {
    name = "google_compute_zones",
    type = "data",
    category = "Compute",
    description = "Gets available zones in a region",
  },
  {
    name = "google_compute_image",
    type = "data",
    category = "Compute",
    description = "Gets information about a compute image",
  },
  {
    name = "google_storage_bucket",
    type = "data",
    category = "Storage",
    description = "Gets information about a storage bucket",
  },
}

--- Get all GCP resources
-- @return table List of GCP resources
function M.get_resources()
  return M.resources
end

--- Search GCP resources
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

--- Get documentation URL for GCP resource
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

--- Fetch documentation for GCP resource
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
    { "resource", "google_compute_instance" },
    { "resource", "google_storage_bucket" },
    { "resource", "google_compute_network" },
    { "resource", "google_container_cluster" },
    { "data", "google_project" },
    { "data", "google_client_config" },
  }
end

return M
