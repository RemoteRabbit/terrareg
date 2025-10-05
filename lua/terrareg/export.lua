--- Export functionality for terrareg.nvim
-- @module terrareg.export

local M = {}

--- Export documentation to file
-- @param doc_data table Documentation data
-- @param format string Export format ("markdown", "json", "html")
-- @param filepath string Output file path
-- @param callback function Callback function
function M.export_documentation(doc_data, format, filepath, callback)
  if not doc_data then
    callback(false, "No documentation data provided")
    return
  end

  local content, error = M.format_documentation(doc_data, format)
  if not content then
    callback(false, error or "Failed to format documentation")
    return
  end

  -- Ensure directory exists
  local dir = vim.fn.fnamemodify(filepath, ":h")
  vim.fn.mkdir(dir, "p")

  -- Write content to file
  local file = io.open(filepath, "w")
  if not file then
    callback(false, "Failed to open file for writing: " .. filepath)
    return
  end

  file:write(content)
  file:close()

  callback(true, "Documentation exported to " .. filepath)
end

--- Format documentation according to specified format
-- @param doc_data table Documentation data
-- @param format string Export format
-- @return string|nil content, string|nil error
function M.format_documentation(doc_data, format)
  if format == "markdown" then
    return M.format_as_markdown(doc_data)
  elseif format == "json" then
    return M.format_as_json(doc_data)
  elseif format == "html" then
    return M.format_as_html(doc_data)
  elseif format == "terraform" then
    return M.format_as_terraform(doc_data)
  else
    return nil, "Unsupported export format: " .. format
  end
end

--- Format documentation as Markdown
-- @param doc_data table Documentation data
-- @return string Markdown content
function M.format_as_markdown(doc_data)
  local lines = {}

  -- Title
  table.insert(lines, "# " .. (doc_data.title or "Terraform Resource Documentation"))
  table.insert(lines, "")

  -- Metadata
  if doc_data.provider or doc_data.resource_type or doc_data.resource_name then
    table.insert(lines, "## Resource Information")
    table.insert(lines, "")
    if doc_data.provider then
      table.insert(lines, "- **Provider**: " .. doc_data.provider)
    end
    if doc_data.resource_type then
      table.insert(lines, "- **Type**: " .. doc_data.resource_type)
    end
    if doc_data.resource_name then
      table.insert(lines, "- **Name**: " .. doc_data.resource_name)
    end
    if doc_data.url then
      table.insert(lines, "- **Documentation**: [" .. doc_data.url .. "](" .. doc_data.url .. ")")
    end
    table.insert(lines, "")
  end

  -- Description
  if doc_data.description then
    table.insert(lines, "## Description")
    table.insert(lines, "")
    table.insert(lines, doc_data.description)
    table.insert(lines, "")
  end

  -- Example Usage
  if doc_data.examples and #doc_data.examples > 0 then
    table.insert(lines, "## Example Usage")
    table.insert(lines, "")
    table.insert(lines, "```hcl")
    table.insert(lines, doc_data.examples[1])
    table.insert(lines, "```")
    table.insert(lines, "")
  elseif doc_data.example then
    table.insert(lines, "## Example Usage")
    table.insert(lines, "")
    table.insert(lines, "```hcl")
    table.insert(lines, doc_data.example)
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  -- Arguments
  if doc_data.arguments and #doc_data.arguments > 0 then
    table.insert(lines, "## Arguments")
    table.insert(lines, "")

    -- Required arguments first
    local required_args = {}
    local optional_args = {}

    for _, arg in ipairs(doc_data.arguments) do
      if arg.required == "Required" then
        table.insert(required_args, arg)
      else
        table.insert(optional_args, arg)
      end
    end

    if #required_args > 0 then
      table.insert(lines, "### Required")
      table.insert(lines, "")
      for _, arg in ipairs(required_args) do
        table.insert(lines, "- **" .. arg.name .. "**: " .. (arg.description or "No description"))
        if arg.type then
          table.insert(lines, "  - Type: `" .. arg.type .. "`")
        end
        if arg.forces_new then
          table.insert(lines, "  - ⚠️ Forces new resource")
        end
      end
      table.insert(lines, "")
    end

    if #optional_args > 0 then
      table.insert(lines, "### Optional")
      table.insert(lines, "")
      for _, arg in ipairs(optional_args) do
        table.insert(lines, "- **" .. arg.name .. "**: " .. (arg.description or "No description"))
        if arg.type then
          table.insert(lines, "  - Type: `" .. arg.type .. "`")
        end
        if arg.default and arg.default ~= "" then
          table.insert(lines, "  - Default: `" .. arg.default .. "`")
        end
        if arg.forces_new then
          table.insert(lines, "  - ⚠️ Forces new resource")
        end
      end
      table.insert(lines, "")
    end
  end

  -- Attributes
  if doc_data.attributes and #doc_data.attributes > 0 then
    table.insert(lines, "## Attributes Reference")
    table.insert(lines, "")
    for _, attr in ipairs(doc_data.attributes) do
      table.insert(lines, "- **" .. attr.name .. "**: " .. (attr.description or "No description"))
      if attr.type then
        table.insert(lines, "  - Type: `" .. attr.type .. "`")
      end
    end
    table.insert(lines, "")
  end

  -- Import
  if doc_data.import then
    table.insert(lines, "## Import")
    table.insert(lines, "")
    table.insert(lines, "```bash")
    table.insert(lines, doc_data.import)
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  -- Footer
  table.insert(lines, "---")
  table.insert(lines, "*Exported by terrareg.nvim on " .. os.date("%Y-%m-%d %H:%M:%S") .. "*")

  return table.concat(lines, "\n")
end

--- Format documentation as JSON
-- @param doc_data table Documentation data
-- @return string JSON content
function M.format_as_json(doc_data)
  -- Add export metadata
  local export_data = vim.deepcopy(doc_data)
  export_data._export = {
    tool = "terrareg.nvim",
    format = "json",
    timestamp = os.date("%Y-%m-%dT%H:%M:%SZ"),
    version = "1.0.0",
  }

  return vim.json.encode(export_data)
end

--- Format documentation as HTML
-- @param doc_data table Documentation data
-- @return string HTML content
function M.format_as_html(doc_data)
  local lines = {}

  -- HTML header
  table.insert(lines, "<!DOCTYPE html>")
  table.insert(lines, '<html lang="en">')
  table.insert(lines, "<head>")
  table.insert(lines, '  <meta charset="UTF-8">')
  table.insert(lines, '  <meta name="viewport" content="width=device-width, initial-scale=1.0">')
  table.insert(lines, "  <title>" .. (doc_data.title or "Terraform Documentation") .. "</title>")
  table.insert(lines, "  <style>")
  table.insert(
    lines,
    "    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }"
  )
  table.insert(lines, "    .container { max-width: 800px; margin: 0 auto; padding: 20px; }")
  table.insert(lines, "    .required { color: #d73a49; }")
  table.insert(lines, "    .optional { color: #6f42c1; }")
  table.insert(lines, "    .forces-new { color: #f66a0a; }")
  table.insert(
    lines,
    "    code { background-color: #f6f8fa; padding: 2px 4px; border-radius: 3px; }"
  )
  table.insert(
    lines,
    "    pre { background-color: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto; }"
  )
  table.insert(lines, "    .arg-item { margin-bottom: 10px; }")
  table.insert(lines, "    .arg-name { font-weight: bold; }")
  table.insert(lines, "    .arg-desc { margin-left: 20px; }")
  table.insert(lines, "  </style>")
  table.insert(lines, "</head>")
  table.insert(lines, "<body>")
  table.insert(lines, '  <div class="container">')

  -- Title
  table.insert(
    lines,
    "    <h1>" .. (doc_data.title or "Terraform Resource Documentation") .. "</h1>"
  )

  -- Description
  if doc_data.description then
    table.insert(lines, "    <h2>Description</h2>")
    table.insert(lines, "    <p>" .. doc_data.description .. "</p>")
  end

  -- Example
  if doc_data.examples and #doc_data.examples > 0 then
    table.insert(lines, "    <h2>Example Usage</h2>")
    table.insert(
      lines,
      '    <pre><code class="language-hcl">' .. doc_data.examples[1] .. "</code></pre>"
    )
  elseif doc_data.example then
    table.insert(lines, "    <h2>Example Usage</h2>")
    table.insert(
      lines,
      '    <pre><code class="language-hcl">' .. doc_data.example .. "</code></pre>"
    )
  end

  -- Arguments
  if doc_data.arguments and #doc_data.arguments > 0 then
    table.insert(lines, "    <h2>Arguments</h2>")

    for _, arg in ipairs(doc_data.arguments) do
      local class = arg.required == "Required" and "required" or "optional"
      table.insert(lines, '    <div class="arg-item">')
      table.insert(lines, '      <span class="arg-name ' .. class .. '">' .. arg.name .. "</span>")
      if arg.required == "Required" then
        table.insert(lines, '      <span class="required">(Required)</span>')
      else
        table.insert(lines, '      <span class="optional">(Optional)</span>')
      end
      if arg.forces_new then
        table.insert(lines, '      <span class="forces-new">[Forces new]</span>')
      end
      table.insert(
        lines,
        '      <div class="arg-desc">' .. (arg.description or "No description") .. "</div>"
      )
      if arg.default and arg.default ~= "" then
        table.insert(
          lines,
          '      <div class="arg-desc">Default: <code>' .. arg.default .. "</code></div>"
        )
      end
      table.insert(lines, "    </div>")
    end
  end

  -- Footer
  table.insert(lines, "    <hr>")
  table.insert(
    lines,
    "    <p><em>Exported by terrareg.nvim on " .. os.date("%Y-%m-%d %H:%M:%S") .. "</em></p>"
  )
  table.insert(lines, "  </div>")
  table.insert(lines, "</body>")
  table.insert(lines, "</html>")

  return table.concat(lines, "\n")
end

--- Format documentation as Terraform configuration template
-- @param doc_data table Documentation data
-- @return string Terraform template
function M.format_as_terraform(doc_data)
  local lines = {}

  if not doc_data.resource_name then
    return "# No resource name available"
  end

  -- Header comment
  table.insert(lines, "# " .. (doc_data.title or doc_data.resource_name))
  if doc_data.description then
    table.insert(lines, "# " .. doc_data.description)
  end
  table.insert(lines, "#")
  table.insert(lines, "# Generated by terrareg.nvim on " .. os.date("%Y-%m-%d %H:%M:%S"))
  if doc_data.url then
    table.insert(lines, "# Documentation: " .. doc_data.url)
  end
  table.insert(lines, "")

  -- Resource block
  local resource_type = doc_data.resource_type or "resource"
  local resource_label = "example"

  if resource_type == "data" then
    table.insert(lines, 'data "' .. doc_data.resource_name .. '" "' .. resource_label .. '" {')
  else
    table.insert(lines, 'resource "' .. doc_data.resource_name .. '" "' .. resource_label .. '" {')
  end

  -- Required arguments
  if doc_data.arguments then
    local required_args = {}
    local optional_args = {}

    for _, arg in ipairs(doc_data.arguments) do
      if arg.required == "Required" then
        table.insert(required_args, arg)
      else
        table.insert(optional_args, arg)
      end
    end

    -- Add required arguments
    for _, arg in ipairs(required_args) do
      local comment = arg.description and " # " .. arg.description or ""
      local value = M.get_default_value_for_type(arg.type)
      table.insert(lines, "  " .. arg.name .. " = " .. value .. comment)
    end

    -- Add optional arguments as comments
    if #optional_args > 0 then
      table.insert(lines, "")
      table.insert(lines, "  # Optional arguments:")
      for _, arg in ipairs(optional_args) do
        local value = arg.default or M.get_default_value_for_type(arg.type)
        local comment = arg.description and " # " .. arg.description or ""
        table.insert(lines, "  # " .. arg.name .. " = " .. value .. comment)
      end
    end
  end

  table.insert(lines, "}")

  return table.concat(lines, "\n")
end

--- Get default value for argument type
-- @param arg_type string|nil Argument type
-- @return string Default value representation
function M.get_default_value_for_type(arg_type)
  if not arg_type then
    return '""'
  end

  local lower_type = arg_type:lower()

  if lower_type:find("string") then
    return '""'
  elseif lower_type:find("number") or lower_type:find("int") then
    return "0"
  elseif lower_type:find("bool") then
    return "false"
  elseif lower_type:find("list") or lower_type:find("array") then
    return "[]"
  elseif lower_type:find("map") or lower_type:find("object") then
    return "{}"
  else
    return '""'
  end
end

--- Show export menu
-- @param doc_data table Documentation data
function M.show_export_menu(doc_data)
  if not doc_data then
    vim.notify("No documentation data to export", vim.log.levels.WARN)
    return
  end

  local formats = {
    { name = "Markdown", value = "markdown", ext = "md" },
    { name = "JSON", value = "json", ext = "json" },
    { name = "HTML", value = "html", ext = "html" },
    { name = "Terraform Template", value = "terraform", ext = "tf" },
  }

  vim.ui.select(formats, {
    prompt = "Export format:",
    format_item = function(item)
      return item.name
    end,
  }, function(selected)
    if not selected then
      return
    end

    -- Generate default filename
    local resource_name = doc_data.resource_name or "terraform_resource"
    local default_filename = resource_name .. "." .. selected.ext

    vim.ui.input({
      prompt = "Export to file: ",
      default = default_filename,
      completion = "file",
    }, function(filepath)
      if not filepath or filepath == "" then
        return
      end

      -- Expand path
      filepath = vim.fn.expand(filepath)

      M.export_documentation(doc_data, selected.value, filepath, function(success, message)
        if success then
          vim.notify(message, vim.log.levels.INFO)
        else
          vim.notify("Export failed: " .. message, vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

--- Quick export to markdown
-- @param doc_data table Documentation data
function M.quick_export_markdown(doc_data)
  if not doc_data then
    vim.notify("No documentation data to export", vim.log.levels.WARN)
    return
  end

  local resource_name = doc_data.resource_name or "terraform_resource"
  local filepath = vim.fn.expand("~/terraform_docs/" .. resource_name .. ".md")

  M.export_documentation(doc_data, "markdown", filepath, function(success, message)
    if success then
      vim.notify(message, vim.log.levels.INFO)

      -- Ask if user wants to open the file
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Open exported file?",
      }, function(choice)
        if choice == "Yes" then
          vim.cmd("edit " .. filepath)
        end
      end)
    else
      vim.notify("Export failed: " .. message, vim.log.levels.ERROR)
    end
  end)
end

return M
