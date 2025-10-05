--- AWS provider implementation for terrareg.nvim
-- @module terrareg.providers.aws

local M = {}

-- Provider metadata
M.name = "aws"
M.display_name = "Amazon Web Services"
M.icon = "☁️"
M.base_url = "https://registry.terraform.io/providers/hashicorp/aws"
M.docs_base_url =
  "https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/website/docs"

--- Get all AWS resources
-- @return table List of AWS resources
function M.get_resources()
  return require("terrareg.aws_resources").get_all_resources()
end

--- Search AWS resources
-- @param query string Search query
-- @return table List of matching resources
function M.search_resources(query)
  return require("terrareg.aws_resources").search_resources(query)
end

--- Get documentation URL for AWS resource
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
  -- Remove aws_ prefix if present since GitHub docs don't have it
  local clean_name = resource_name
  if clean_name:match("^aws_") then
    clean_name = clean_name:gsub("^aws_", "")
  end

  if resource_type == "resource" then
    return M.docs_base_url .. "/r/" .. clean_name .. ".html.markdown"
  elseif resource_type == "data" then
    return M.docs_base_url .. "/d/" .. clean_name .. ".html.markdown"
  else
    error("Invalid resource type. Use 'resource' or 'data'")
  end
end

--- Fetch documentation for AWS resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @param version string|nil Version
-- @param callback function Callback function
function M.fetch_documentation(resource_type, resource_name, version, callback)
  -- Delegate to the main docs module (which already handles AWS)
  require("terrareg.docs").fetch_documentation(resource_type, resource_name, version, callback)
end

--- Get provider versions
-- @param callback function Callback function
function M.fetch_versions(callback)
  local http = require("terrareg.http")
  local url = "https://registry.terraform.io/v1/providers/hashicorp/aws/versions"

  http.get(url, function(success, response, error)
    if success then
      local ok, data = pcall(vim.fn.json_decode, response.body)
      if ok and data and data.versions then
        callback(true, data.versions, nil)
      else
        callback(false, nil, "Failed to parse versions response")
      end
    else
      callback(false, nil, error)
    end
  end)
end

--- Get popular resources for prefetching
-- @return table List of popular resource identifiers
function M.get_popular_resources()
  return {
    { "resource", "aws_s3_bucket" },
    { "resource", "aws_instance" },
    { "resource", "aws_vpc" },
    { "resource", "aws_subnet" },
    { "resource", "aws_security_group" },
    { "resource", "aws_iam_role" },
    { "resource", "aws_lambda_function" },
    { "data", "aws_ami" },
    { "data", "aws_vpc" },
    { "data", "aws_availability_zones" },
    { "data", "aws_caller_identity" },
  }
end

return M
