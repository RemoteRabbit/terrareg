-- Demo script with predefined inputs
-- Import the required libraries
local http = require("socket.http")
local ltn12 = require("ltn12")

-- Simple JSON decoder (basic implementation for our needs)
local function parseJson(jsonStr)
  -- Remove whitespace
  jsonStr = jsonStr:gsub("%s+", "")

  -- Simple parser for versions array
  if jsonStr:match('"versions"%s*:%s*%[') then
    local versions = {}
    for versionBlock in jsonStr:gmatch('{[^}]*"version"%s*:%s*"([^"]+)"[^}]*}') do
      local version = versionBlock
      local protocols = {}
      local protocolsStr = jsonStr:match(
        '"version"%s*:%s*"' .. version:gsub("%-", "%%-") .. '"[^}]*"protocols"%s*:%s*%[([^%]]+)%]'
      )
      if protocolsStr then
        for protocol in protocolsStr:gmatch('"([^"]+)"') do
          table.insert(protocols, protocol)
        end
      end
      table.insert(versions, { version = version, protocols = protocols })
    end
    return { versions = versions }
  end

  return {}
end

-- Function to make an HTTP GET request
local function httpGet(url)
  local response = {}
  local body = {}

  -- Make the HTTP request
  local request, code, responseHeaders = http.request({
    url = url,
    method = "GET",
    sink = ltn12.sink.table(body),
  })

  if code ~= 200 then
    error("HTTP request failed with status code: " .. code)
  end

  -- Combine the response parts
  response.body = table.concat(body)
  response.headers = responseHeaders
  response.code = code

  return response
end

-- Function to get AWS provider versions
local function getAwsProviderVersions()
  local url = "https://registry.terraform.io/v1/providers/hashicorp/aws/versions"
  local response = httpGet(url)
  local data = parseJson(response.body)
  return data.versions
end

-- Function to get AWS provider documentation URL
local function getAwsDocumentationUrl(resourceType, resourceName, version)
  version = version or "latest"
  local baseUrl = "https://registry.terraform.io/providers/hashicorp/aws/" .. version .. "/docs"

  if resourceType == "resource" then
    return baseUrl .. "/resources/" .. resourceName
  elseif resourceType == "data" then
    return baseUrl .. "/data-sources/" .. resourceName
  else
    error("Invalid resource type. Use 'resource' or 'data'")
  end
end

-- Function to display provider versions
local function displayProviderVersions(versions, limit)
  limit = limit or 5
  print("\nAvailable AWS Provider Versions (showing latest " .. limit .. "):")
  print("=" .. string.rep("=", 50))

  for i = 1, math.min(limit, #versions) do
    local version = versions[i]
    print(string.format("Version: %s", version.version))
    print(string.format("Protocols: %s", table.concat(version.protocols, ", ")))
    print("-" .. string.rep("-", 40))
  end
end

-- Function to display resource documentation info
local function displayResourceInfo(resourceType, resourceName, version)
  local docUrl = getAwsDocumentationUrl(resourceType, resourceName, version)

  print("\nResource Information:")
  print("=" .. string.rep("=", 50))
  print(string.format("Type: %s", resourceType))
  print(string.format("Name: %s", resourceName))
  print(string.format("Version: %s", version or "latest"))
  print(string.format("Documentation URL: %s", docUrl))

  -- Try to fetch the documentation page
  print("\nFetching documentation...")
  local success, response = pcall(httpGet, docUrl)

  if success then
    print("✓ Documentation page found")
    print("Status: " .. response.code)

    -- Extract title from HTML
    local title = response.body:match("<title>(.-)</title>")
    if title then
      print("Page title: " .. title)
    end

    -- Show first few lines of content
    local lines = {}
    for line in response.body:gmatch("[^\r\n]+") do
      table.insert(lines, line)
      if #lines >= 10 then
        break
      end
    end

    print("\nFirst few lines of documentation:")
    for i, line in ipairs(lines) do
      print(string.format("%2d: %s", i, line:sub(1, 80) .. (line:len() > 80 and "..." or "")))
    end
  else
    print("✗ Failed to fetch documentation: " .. tostring(response))
  end
end

-- Demo function with predefined inputs
local function demo()
  print("AWS Provider Documentation Fetcher - DEMO")
  print("=" .. string.rep("=", 45))

  -- Get AWS provider versions
  print("Fetching AWS provider versions...")
  local versions = getAwsProviderVersions()
  displayProviderVersions(versions, 3)

  print("\n" .. string.rep("=", 60))
  print("DEMO 1: AWS S3 Bucket Resource")
  print(string.rep("=", 60))
  displayResourceInfo("resource", "aws_s3_bucket", nil)

  print("\n" .. string.rep("=", 60))
  print("DEMO 2: AWS Instance Data Source")
  print(string.rep("=", 60))
  displayResourceInfo("data", "aws_instance", nil)
end

-- Run the demo function
demo()
