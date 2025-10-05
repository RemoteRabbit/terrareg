#!/usr/bin/env lua
-- Generate API documentation from Lua source files
-- Outputs markdown files that VitePress can consume

local function parse_lua_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    error("Could not open file: " .. filepath)
  end

  local content = file:read("*all")
  file:close()

  local functions = {}
  local current_func = nil
  local module_info = {}

  -- Parse module-level information
  for line in content:gmatch("[^\r\n]+") do
    local module_desc = line:match("^%-%-%- (.+)")
    if module_desc and not module_info.description then
      module_info.description = module_desc
    end

    local module_name = line:match("^%-%- @module (.+)")
    if module_name then
      module_info.name = module_name
    end

    local author = line:match("^%-%- @author (.+)")
    if author then
      module_info.author = author
    end

    local license = line:match("^%-%- @license (.+)")
    if license then
      module_info.license = license
    end
  end

  -- Parse functions
  local i = 1
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    lines[i] = line
    i = i + 1
  end

  for j, line in ipairs(lines) do
    -- Check for function documentation start
    local func_desc = line:match("^%-%-%- (.+)")
    if func_desc and lines[j + 1] and not lines[j + 1]:match("^%-%-") then
      current_func = {
        description = func_desc,
        params = {},
        returns = {},
        usage = {},
      }
    end

    -- Parse parameters
    local param_info = line:match("^%-%- @param (%w+) (.+)")
    if param_info and current_func then
      local param_name, param_desc = param_info:match("(%w+) (.+)")
      if param_name and param_desc then
        table.insert(current_func.params, {
          name = param_name,
          description = param_desc,
        })
      end
    end

    -- Parse return values
    local return_info = line:match("^%-%- @return (.+)")
    if return_info and current_func then
      table.insert(current_func.returns, return_info)
    end

    -- Parse usage examples
    local usage_info = line:match("^%-%- @usage (.+)")
    if usage_info and current_func then
      table.insert(current_func.usage, usage_info)
    end

    -- Find function declaration
    local func_pattern = "^function%s+[%w%.]+%.(%w+)%s*%(([^)]*)%)"
    local func_name, func_args = line:match(func_pattern)
    if func_name and current_func then
      current_func.name = func_name
      current_func.args = func_args
      functions[func_name] = current_func
      current_func = nil
    end
  end

  -- Parse configuration table
  local config_start = content:match("M%.config%s*=%s*{([^}]+)}")
  local config_fields = {}
  if config_start then
    for field_line in config_start:gmatch("[^\r\n]+") do
      local field_name, field_value = field_line:match("%s*(%w+)%s*=%s*(.+),?")
      if field_name and field_value then
        config_fields[field_name] = field_value:gsub(",$", "")
      end
    end
  end

  return {
    module = module_info,
    functions = functions,
    config = config_fields,
  }
end

local function generate_markdown(parsed_data, output_file)
  local md_content = {}

  -- Header
  table.insert(md_content, "# API Reference")
  table.insert(md_content, "")
  table.insert(
    md_content,
    "> 🤖 **Auto-generated from source code** - Last updated: " .. os.date("%Y-%m-%d %H:%M:%S")
  )
  table.insert(md_content, "")

  if parsed_data.module.description then
    table.insert(md_content, parsed_data.module.description)
    table.insert(md_content, "")
  end

  -- Module info
  if parsed_data.module.author or parsed_data.module.license then
    table.insert(md_content, "## Module Information")
    table.insert(md_content, "")
    if parsed_data.module.author then
      table.insert(md_content, "- **Author**: " .. parsed_data.module.author)
    end
    if parsed_data.module.license then
      table.insert(md_content, "- **License**: " .. parsed_data.module.license)
    end
    table.insert(md_content, "")
  end

  -- Configuration
  if next(parsed_data.config) then
    table.insert(md_content, "## Configuration")
    table.insert(md_content, "")
    table.insert(md_content, "Default configuration:")
    table.insert(md_content, "")
    table.insert(md_content, "```lua")
    table.insert(md_content, "require('terrareg').setup({")
    for field, value in pairs(parsed_data.config) do
      table.insert(md_content, "  " .. field .. " = " .. value .. ",")
    end
    table.insert(md_content, "})")
    table.insert(md_content, "```")
    table.insert(md_content, "")

    -- Configuration table
    table.insert(md_content, "| Option | Default | Description |")
    table.insert(md_content, "|--------|---------|-------------|")
    for field, value in pairs(parsed_data.config) do
      table.insert(md_content, "| `" .. field .. "` | `" .. value .. "` | [Add description] |")
    end
    table.insert(md_content, "")
  end

  -- Functions
  if next(parsed_data.functions) then
    table.insert(md_content, "## Functions")
    table.insert(md_content, "")

    for func_name, func_data in pairs(parsed_data.functions) do
      table.insert(md_content, "### `" .. func_name .. "(" .. (func_data.args or "") .. ")`")
      table.insert(md_content, "")

      if func_data.description then
        table.insert(md_content, func_data.description)
        table.insert(md_content, "")
      end

      -- Parameters
      if #func_data.params > 0 then
        table.insert(md_content, "**Parameters:**")
        table.insert(md_content, "")
        for _, param in ipairs(func_data.params) do
          table.insert(md_content, "- `" .. param.name .. "` - " .. param.description)
        end
        table.insert(md_content, "")
      end

      -- Returns
      if #func_data.returns > 0 then
        table.insert(md_content, "**Returns:**")
        table.insert(md_content, "")
        for _, ret in ipairs(func_data.returns) do
          table.insert(md_content, "- " .. ret)
        end
        table.insert(md_content, "")
      end

      -- Usage examples
      if #func_data.usage > 0 then
        table.insert(md_content, "**Example:**")
        table.insert(md_content, "")
        table.insert(md_content, "```lua")
        for _, usage in ipairs(func_data.usage) do
          table.insert(md_content, usage)
        end
        table.insert(md_content, "```")
        table.insert(md_content, "")
      end

      table.insert(md_content, "---")
      table.insert(md_content, "")
    end
  end

  -- Write to file
  local file = io.open(output_file, "w")
  if not file then
    error("Could not open output file: " .. output_file)
  end

  file:write(table.concat(md_content, "\n"))
  file:close()

  print("✅ Generated: " .. output_file)
end

-- Main execution
local function main()
  print("🤖 Generating API documentation from source code...")

  -- Parse main module
  local main_data = parse_lua_file("lua/terrareg/init.lua")

  -- Generate API reference
  generate_markdown(main_data, "docs/api/auto-generated.md")

  print("🎉 API documentation generation complete!")
end

-- Run if called directly
if arg and arg[0]:match("generate%-api%-docs%.lua$") then
  main()
end

return { parse_lua_file = parse_lua_file, generate_markdown = generate_markdown }
