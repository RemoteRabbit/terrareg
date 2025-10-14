--- Documentation parser for terrareg.nvim
--- Handles parsing of Terraform provider documentation from HTML and Markdown
--- @module terrareg.parser

local M = {}

--- Extract text content from HTML tags
--- @param html string HTML content
--- @param pattern string Lua pattern to match
--- @return string? Extracted text content
local function extract_text_from_tag(html, pattern)
  local content = html:match(pattern)
  if content then
    -- Remove HTML tags and clean up whitespace
    content = content:gsub("<[^>]*>", "")
    content = content:gsub("%s+", " ")
    content = content:gsub("^%s*(.-)%s*$", "%1")
  end
  return content
end

--- Extract description from Terraform documentation
--- Parses both HTML and Markdown formats to find resource/data source descriptions
--- @param content string HTML or Markdown content
--- @return string? Description text
function M.extract_description(content)
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
      local desc = extract_text_from_tag(content, pattern)
      if desc and desc:len() > 20 then
        return desc
      end
    end
  end

  return nil
end

--- Parse argument details from description
--- Extracts metadata like required status, default values, and forces_new from description text
--- @param description string Full argument description
--- @return table Parsed details with required, default, and clean description
local function parse_argument_details(description)
  local details = {
    required = "Unknown",
    default = "",
    description = description,
    forces_new = false,
  }

  -- Check if required or optional
  if description:match("%(Required[^%)]*%)") then
    details.required = "Required"
  elseif description:match("%(Optional[^%)]*%)") then
    details.required = "Optional"
  end

  -- Extract default value
  local default_patterns = {
    "Default:%s*`([^`]+)`",
    "Default:%s*([^%.]+)%.",
    "Defaults to%s*`([^`]+)`",
    "Defaults to%s*([^%.]+)%.",
    "default is%s*`([^`]+)`",
    "default is%s*([^%.]+)%.",
  }

  for _, pattern in ipairs(default_patterns) do
    local default_val = description:match(pattern)
    if default_val then
      details.default = default_val:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
      break
    end
  end

  -- Check for forces new resource
  if description:match("Forces new resource") then
    details.forces_new = true
  end

  -- Clean up description by removing the parsed parts
  local clean_desc = description
  clean_desc = clean_desc:gsub("%(Required[^%)]*%)", "")
  clean_desc = clean_desc:gsub("%(Optional[^%)]*%)", "")
  clean_desc = clean_desc:gsub("Default:%s*`[^`]+`[%.%,]?%s*", "")
  clean_desc = clean_desc:gsub("Default:%s*[^%.]+%.", "")
  clean_desc = clean_desc:gsub("Defaults to%s*`[^`]+`[%.%,]?%s*", "")
  clean_desc = clean_desc:gsub("Defaults to%s*[^%.]+%.", "")
  clean_desc = clean_desc:gsub("default is%s*`[^`]+`[%.%,]?%s*", "")
  clean_desc = clean_desc:gsub("default is%s*[^%.]+%.", "")
  clean_desc = clean_desc:gsub("^%s*(.-)%s*$", "%1") -- trim

  details.description = clean_desc

  return details
end

--- Extract arguments/attributes from documentation
--- Parses documentation to extract argument definitions with metadata
--- @param content string HTML or Markdown content
--- @return table[] List of arguments with enhanced details
function M.extract_arguments(content)
  local arguments = {}

  -- If content is markdown
  if content:match("^%s*%-%-%-") or content:match("# ") then
    -- Look for argument reference section in markdown
    local arg_section = content:match("## Argument Reference\n(.-)##")
      or content:match("## Arguments\n(.-)##")
    if arg_section then
      -- Extract markdown list items
      for line in arg_section:gmatch("[^\n]+") do
        local name = line:match("^%s*%*%s*`([^`]+)`") -- * `argument_name`
        if name then
          local full_desc = line:match("`[^`]+`%s*%-?%s*(.+)") or ""
          local details = parse_argument_details(full_desc)
          table.insert(arguments, {
            name = name,
            required = details.required,
            default = details.default,
            description = details.description,
            forces_new = details.forces_new,
          })
        end
      end
    end
  else
    -- HTML format - look for argument sections
    local arg_section = content:match("<h2[^>]*>[^<]*[Aa]rguments?[^<]*</h2>(.-)<h[12][^>]*>")
    if not arg_section then
      arg_section = content:match("<h3[^>]*>[^<]*[Aa]rguments?[^<]*</h3>(.-)<h[123][^>]*>")
    end

    if arg_section then
      -- Extract list items or definition terms
      for arg in arg_section:gmatch("<li[^>]*>(.-)</li>") do
        local name = arg:match("<code[^>]*>([^<]+)</code>")
        local full_desc = extract_text_from_tag(arg, "<[^>]*>(.+)")
        if name and full_desc then
          local details = parse_argument_details(full_desc)
          table.insert(arguments, {
            name = name,
            required = details.required,
            default = details.default,
            description = details.description,
            forces_new = details.forces_new,
          })
        end
      end

      -- Try dt/dd pattern
      if #arguments == 0 then
        local dt, dd = arg_section:gmatch("<dt[^>]*>(.-)</dt>%s*<dd[^>]*>(.-)</dd>")
        for name, full_desc in dt, dd do
          name = extract_text_from_tag(name, "(.+)")
          full_desc = extract_text_from_tag(full_desc, "(.+)")
          if name and full_desc then
            local details = parse_argument_details(full_desc)
            table.insert(arguments, {
              name = name,
              required = details.required,
              default = details.default,
              description = details.description,
              forces_new = details.forces_new,
            })
          end
        end
      end
    end
  end

  return arguments
end

--- Extract example usage from documentation
--- Finds and extracts Terraform code examples from documentation
--- @param content string HTML or Markdown content
--- @return string[] List of code examples
function M.extract_examples(content)
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
      local clean_code = extract_text_from_tag(code, "(.+)")
      if clean_code and clean_code:len() > 10 then
        table.insert(examples, clean_code)
      end
    end

    -- Look for pre blocks
    if #examples == 0 then
      for code in content:gmatch("<pre[^>]*>(.-)</pre>") do
        local clean_code = extract_text_from_tag(code, "(.+)")
        if clean_code and clean_code:match('resource%s+"') then
          table.insert(examples, clean_code)
        end
      end
    end
  end

  return examples
end

return M
