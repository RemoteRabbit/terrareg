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

  -- Make the HTTP request with user agent to get better content
  local request, code, responseHeaders = http.request({
    url = url,
    method = "GET",
    headers = {
      ["User-Agent"] = "TerraregLua/1.0",
      ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
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

-- Try alternative documentation source (GitHub raw docs)
local function getAlternativeDocUrl(resourceType, resourceName)
  local baseUrl =
    "https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/website/docs"

  -- Remove aws_ prefix if present since GitHub docs don't have it
  local cleanName = resourceName
  if cleanName:match("^aws_") then
    cleanName = cleanName:gsub("^aws_", "")
  end

  if resourceType == "resource" then
    return baseUrl .. "/r/" .. cleanName .. ".html.markdown"
  elseif resourceType == "data" then
    return baseUrl .. "/d/" .. cleanName .. ".html.markdown"
  else
    error("Invalid resource type. Use 'resource' or 'data'")
  end
end

-- Function to get user input
local function getUserInput(prompt)
  io.write(prompt .. ": ")
  io.flush()
  return io.read()
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

-- Function to extract text content from HTML tags
local function extractTextFromTag(html, tagPattern)
  local content = html:match(tagPattern)
  if content then
    -- Remove HTML tags and clean up whitespace
    content = content:gsub("<[^>]*>", "")
    content = content:gsub("%s+", " ")
    content = content:gsub("^%s*(.-)%s*$", "%1")
  end
  return content
end

-- Function to extract description from Terraform docs
local function extractDescription(content)
  -- If content is markdown, extract description differently
  if content:match("^%s*%-%-%-") or content:match("# ") then
    -- Markdown format - get first paragraph after title
    local desc = content:match("# [^\n]+\n\n([^\n]+)")
    if not desc then
      desc = content:match("## Description\n\n([^\n#]+)")
    end
    if not desc then
      -- Get first non-empty line that looks like description
      for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$") -- trim whitespace
        if
          line:len() > 20
          and not line:match("^#")
          and not line:match("^%-%-%-")
          and not line:match("^```")
        then
          desc = line
          break
        end
      end
    end
    return desc
  else
    -- HTML format - try multiple patterns for description
    local patterns = {
      '<p class="description">(.-)</p>',
      '<div class="description">(.-)</div>',
      "<section[^>]*>%s*<p[^>]*>(.-)</p>",
      '<div[^>]*class="[^"]*description[^"]*"[^>]*>(.-)</div>',
      -- Generic paragraph after heading
      "<h1[^>]*>.-</h1>%s*<p[^>]*>(.-)</p>",
    }

    for _, pattern in ipairs(patterns) do
      local desc = extractTextFromTag(content, pattern)
      if desc and desc:len() > 20 then
        return desc
      end
    end
  end

  return nil
end

-- Function to extract arguments/attributes
local function extractArguments(content)
  local arguments = {}

  -- If content is markdown
  if content:match("^%s*%-%-%-") or content:match("# ") then
    -- Look for argument reference section in markdown
    local argSection = content:match("## Argument Reference\n(.-)##")
      or content:match("## Arguments\n(.-)##")
    if argSection then
      -- Extract markdown list items
      for line in argSection:gmatch("[^\n]+") do
        local name = line:match("^%s*%*%s*`([^`]+)`") -- * `argument_name`
        if name then
          local desc = line:match("`[^`]+`%s*%-?%s*(.+)") or ""
          table.insert(arguments, { name = name, description = desc:sub(1, 100) })
        end
      end
    end
  else
    -- HTML format - look for argument sections
    local argSection = content:match("<h2[^>]*>[^<]*[Aa]rguments?[^<]*</h2>(.-)<h[12][^>]*>")
    if not argSection then
      argSection = content:match("<h3[^>]*>[^<]*[Aa]rguments?[^<]*</h3>(.-)<h[123][^>]*>")
    end

    if argSection then
      -- Extract list items or definition terms
      for arg in argSection:gmatch("<li[^>]*>(.-)</li>") do
        local name = arg:match("<code[^>]*>([^<]+)</code>")
        local desc = extractTextFromTag(arg, "<[^>]*>(.+)")
        if name and desc then
          table.insert(arguments, { name = name, description = desc:sub(1, 100) })
        end
      end

      -- Try dt/dd pattern
      if #arguments == 0 then
        local dt, dd = argSection:gmatch("<dt[^>]*>(.-)</dt>%s*<dd[^>]*>(.-)</dd>")
        for name, desc in dt, dd do
          name = extractTextFromTag(name, "(.+)")
          desc = extractTextFromTag(desc, "(.+)")
          if name and desc then
            table.insert(arguments, { name = name, description = desc:sub(1, 100) })
          end
        end
      end
    end
  end

  return arguments
end

-- Function to extract example usage
local function extractExamples(content)
  local examples = {}

  -- If content is markdown
  if content:match("^%s*%-%-%-") or content:match("# ") then
    -- Look for code blocks in markdown
    for code in content:gmatch("```hcl\n(.-)\n```") do
      if code and code:len() > 10 and code:match('resource%s+"') then
        table.insert(examples, code)
      end
    end

    -- Try other code block formats
    if #examples == 0 then
      for code in content:gmatch("```terraform\n(.-)\n```") do
        if code and code:len() > 10 then
          table.insert(examples, code)
        end
      end
    end

    -- Try simple ``` blocks
    if #examples == 0 then
      for code in content:gmatch("```\n(.-)\n```") do
        if code and code:len() > 10 and code:match('resource%s+"') then
          table.insert(examples, code)
        end
      end
    end
  else
    -- HTML format - look for code blocks
    for code in content:gmatch('<code[^>]*class="[^"]*terraform[^"]*"[^>]*>(.-)</code>') do
      local cleanCode = extractTextFromTag(code, "(.+)")
      if cleanCode and cleanCode:len() > 10 then
        table.insert(examples, cleanCode)
      end
    end

    -- Look for pre blocks
    if #examples == 0 then
      for code in content:gmatch("<pre[^>]*>(.-)</pre>") do
        local cleanCode = extractTextFromTag(code, "(.+)")
        if cleanCode and cleanCode:match('resource%s+"') then
          table.insert(examples, cleanCode)
        end
      end
    end
  end

  return examples
end

-- Function to display formatted documentation
local function displayFormattedDocs(html, resourceName)
  print("\n" .. string.rep("=", 60))
  print("📖 TERRAFORM DOCUMENTATION SUMMARY")
  print(string.rep("=", 60))

  -- Extract and display description
  local description = extractDescription(html)
  if description then
    print("\n📝 Description:")
    print(string.rep("-", 20))
    -- Wrap text at 70 characters
    local wrapped = ""
    local line = ""
    for word in description:gmatch("%S+") do
      if line:len() + word:len() + 1 > 70 then
        wrapped = wrapped .. line .. "\n"
        line = word
      else
        line = line .. (line == "" and "" or " ") .. word
      end
    end
    wrapped = wrapped .. line
    print(wrapped)
  end

  -- Extract and display arguments
  local arguments = extractArguments(html)
  if #arguments > 0 then
    print("\n⚙️  Key Arguments:")
    print(string.rep("-", 20))
    for i, arg in ipairs(arguments) do
      print(string.format("• %s", arg.name))
      if arg.description:len() > 0 then
        print(string.format("  %s", arg.description))
      end
      if i >= 5 then
        print(string.format("  ... and %d more arguments", #arguments - 5))
        break
      end
    end
  end

  -- Extract and display examples
  local examples = extractExamples(html)
  if #examples > 0 then
    print("\n💡 Example Usage:")
    print(string.rep("-", 20))
    local example = examples[1]
    -- Limit example length
    if example:len() > 300 then
      example = example:sub(1, 300) .. "\n... (truncated)"
    end
    print(example)
  end

  print("\n" .. string.rep("=", 60))
end

-- Function to display resource documentation info
local function displayResourceInfo(resourceType, resourceName, version)
  local docUrl = getAwsDocumentationUrl(resourceType, resourceName, version)
  local altUrl = getAlternativeDocUrl(resourceType, resourceName)

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
    -- Check if we got actual content (not just JavaScript-rendered page)
    local hasContent = false

    -- Look for actual documentation content indicators
    if
      response.body:match("Argument Reference")
      or response.body:match("argument")
      or response.body:match("Example Usage")
      or response.body:match("<h2")
    then
      hasContent = true
    end

    if hasContent then
      print("✓ Registry documentation found")

      -- Extract title from HTML
      local title = response.body:match("<title>(.-)</title>")
      if title then
        title = extractTextFromTag(title, "(.+)")
        print("📄 " .. title)
      end

      -- Display formatted documentation
      displayFormattedDocs(response.body, resourceName)
    else
      print("✗ Registry returned empty content (JavaScript-rendered), trying GitHub source...")
      success = false -- Force fallback to GitHub
    end
  end

  if not success then
    print("Alternative URL: " .. altUrl)

    -- Try alternative source
    local altSuccess, altResponse = pcall(httpGet, altUrl)
    if altSuccess then
      print("✓ GitHub documentation found")
      print("📄 " .. resourceName .. " (from GitHub)")

      -- Display formatted documentation from markdown
      displayFormattedDocs(altResponse.body, resourceName)
    else
      print("✗ Failed to fetch from both sources")
      if response then
        print("Registry error: " .. tostring(response))
      end
      print("GitHub error: " .. tostring(altResponse))
    end
  end
end

-- Main interactive function
local function main()
  print("AWS Provider Documentation Fetcher")
  print("=" .. string.rep("=", 40))

  -- Get AWS provider versions
  print("Fetching AWS provider versions...")
  local versions = getAwsProviderVersions()
  displayProviderVersions(versions)

  -- Get user input for resource type
  local resourceType = getUserInput("\nEnter resource type (resource/data)")

  -- Validate resource type
  if resourceType ~= "resource" and resourceType ~= "data" then
    print("Invalid resource type. Please use 'resource' or 'data'")
    return
  end

  -- Get user input for resource name
  local resourceName =
    getUserInput("Enter " .. resourceType .. " name (e.g., aws_instance, aws_s3_bucket)")

  -- Get user input for version (optional)
  local version = getUserInput("Enter provider version (press enter for latest)")
  if version == "" then
    version = nil
  end

  -- Display resource information and fetch documentation
  displayResourceInfo(resourceType, resourceName, version)
end

-- Run the main function
main()
