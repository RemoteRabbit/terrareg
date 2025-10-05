--- Documentation fetcher for terrareg.nvim
-- @module terrareg.docs

local http = require("terrareg.http")
local parser = require("terrareg.parser")

local M = {}

--- Enable debug mode
-- @param enabled boolean Whether to enable debug mode
function M.set_debug(enabled)
  vim.g.terrareg_debug = enabled
end

--- Get AWS provider documentation URL
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource (e.g., "aws_s3_bucket")
-- @param version string|nil Provider version (defaults to "latest")
-- @return string Documentation URL
local function get_aws_documentation_url(resource_type, resource_name, version)
  version = version or "latest"
  local base_url = "https://registry.terraform.io/providers/hashicorp/aws/" .. version .. "/docs"

  if resource_type == "resource" then
    return base_url .. "/resources/" .. resource_name
  elseif resource_type == "data" then
    return base_url .. "/data-sources/" .. resource_name
  else
    error("Invalid resource type. Use 'resource' or 'data'")
  end
end

--- Get alternative documentation URL from GitHub
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @return string GitHub documentation URL
local function get_alternative_doc_url(resource_type, resource_name)
  local base_url =
    "https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/website/docs"

  -- Remove aws_ prefix if present since GitHub docs don't have it
  local clean_name = resource_name
  if clean_name:match("^aws_") then
    clean_name = clean_name:gsub("^aws_", "")
  end

  if resource_type == "resource" then
    return base_url .. "/r/" .. clean_name .. ".html.markdown"
  elseif resource_type == "data" then
    return base_url .. "/d/" .. clean_name .. ".html.markdown"
  else
    error("Invalid resource type. Use 'resource' or 'data'")
  end
end

--- Check if content has actual documentation (not just JavaScript)
-- @param content string HTML content
-- @return boolean True if content has documentation
local function has_documentation_content(content)
  return content:match("Argument Reference")
    or content:match("argument")
    or content:match("Example Usage")
    or content:match("<h2")
end

--- Fetch documentation for a resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param version string|nil Provider version
-- @param callback function Callback function (success, doc_data, error)
function M.fetch_documentation(resource_type, resource_name, version, callback)
  local registry_url = get_aws_documentation_url(resource_type, resource_name, version)
  local github_url = get_alternative_doc_url(resource_type, resource_name)

  if vim.g.terrareg_debug then
    print("Fetching documentation for: " .. resource_type .. " " .. resource_name)
    print("Registry URL: " .. registry_url)
    print("GitHub URL: " .. github_url)
  end

  -- Try registry first
  http.get(registry_url, function(success, response, error)
    if vim.g.terrareg_debug then
      print("Registry response - Success: " .. tostring(success))
      if error then
        print("Registry error: " .. error)
      end
    end

    if success and response and has_documentation_content(response.body) then
      -- Successfully got content from registry
      if vim.g.terrareg_debug then
        print("Registry content length: " .. #response.body)
      end

      local doc_data = {
        source = "registry",
        url = registry_url,
        resource_type = resource_type,
        resource_name = resource_name,
        provider = "aws",
        title = response.body:match("<title>(.-)</title>") or resource_name,
        description = parser.extract_description(response.body),
        arguments = parser.extract_arguments(response.body),
        examples = parser.extract_examples(response.body),
      }
      callback(true, doc_data, nil)
    else
      -- Fallback to GitHub
      if vim.g.terrareg_debug then
        print("Registry failed, trying GitHub fallback...")
      end

      http.get(github_url, function(alt_success, alt_response, alt_error)
        if vim.g.terrareg_debug then
          print("GitHub response - Success: " .. tostring(alt_success))
          if alt_error then
            print("GitHub error: " .. alt_error)
          end
        end

        if alt_success and alt_response then
          if vim.g.terrareg_debug then
            print("GitHub content length: " .. #alt_response.body)
          end

          local doc_data = {
            source = "github",
            url = github_url,
            resource_type = resource_type,
            resource_name = resource_name,
            provider = "aws",
            title = resource_name .. " (GitHub)",
            description = parser.extract_description(alt_response.body),
            arguments = parser.extract_arguments(alt_response.body),
            examples = parser.extract_examples(alt_response.body),
          }
          callback(true, doc_data, nil)
        else
          local registry_error = error or "Registry: unknown error"
          local github_error = alt_error or "GitHub: unknown error"
          local combined_error = string.format(
            "Failed to fetch from registry (%s) and GitHub (%s)",
            registry_error,
            github_error
          )

          if vim.g.terrareg_debug then
            print("Both sources failed: " .. combined_error)
          end

          callback(false, nil, combined_error)
        end
      end)
    end
  end)
end

--- Fetch documentation synchronously
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param version string|nil Provider version
-- @return boolean success, table|nil doc_data, string|nil error
function M.fetch_documentation_sync(resource_type, resource_name, version)
  local result = {}
  local done = false

  M.fetch_documentation(resource_type, resource_name, version, function(success, doc_data, error)
    result.success = success
    result.doc_data = doc_data
    result.error = error
    done = true
  end)

  -- Wait for completion (with timeout)
  local timeout = 30000 -- 30 seconds
  local start_time = vim.loop.now()

  while not done and (vim.loop.now() - start_time) < timeout do
    vim.wait(10)
  end

  if not done then
    return false, nil, "Request timeout"
  end

  return result.success, result.doc_data, result.error
end

return M
