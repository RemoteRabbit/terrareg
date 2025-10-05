-- Dynamic vimdoc generation from LuaDoc annotations
-- This script parses Lua files for LuaDoc comments and generates vimdoc

local M = {}

-- Parse a Lua file for LuaDoc annotations
local function parse_lua_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local functions = {}
  local current_func = nil

  local module_info = {}

  for line in content:gmatch("[^\r\n]+") do
    -- Module documentation
    if line:match("^%-%-%- (.+)") and not current_func then
      if not module_info.description then
        module_info.description = line:match("^%-%-%- (.+)")
      end
    elseif line:match("^%-%- @module (.+)") then
      module_info.name = line:match("^%-%- @module (.+)")
      -- in_module_doc = true
    elseif line:match("^%-%- @author (.+)") then
      module_info.author = line:match("^%-%- @author (.+)")
    elseif line:match("^%-%- @license (.+)") then
      module_info.license = line:match("^%-%- @license (.+)")

    -- Function documentation
    elseif line:match("^%-%-%- (.+)") then
      if not current_func then
        current_func = {
          description = line:match("^%-%-%- (.+)"),
          params = {},
          returns = {},
          usage = {},
          tags = {},
        }
      end
    elseif line:match("^%-%- (.+)") and current_func then
      local content_line = line:match("^%-%- (.+)")

      -- Parse @param
      if content_line:match("^@param (%w+) (.+)") then
        local param_name, param_desc = content_line:match("^@param (%w+) (.+)")
        table.insert(current_func.params, { name = param_name, desc = param_desc })

      -- Parse @return
      elseif content_line:match("^@return (.+)") then
        table.insert(current_func.returns, content_line:match("^@return (.+)"))

      -- Parse @usage
      elseif content_line:match("^@usage (.+)") then
        table.insert(current_func.usage, content_line:match("^@usage (.+)"))

      -- Parse other tags
      elseif content_line:match("^@(%w+) (.+)") then
        local tag, value = content_line:match("^@(%w+) (.+)")
        current_func.tags[tag] = value

      -- Continuation of description
      else
        if current_func.description then
          current_func.description = current_func.description .. " " .. content_line
        end
      end

    -- Function definition
    elseif
      line:match("^function [%w%.]-%.?([%w_]+)%(") or line:match("^local function ([%w_]+)%(")
    then
      if current_func then
        local func_name = line:match("^function [%w%.]-%.?([%w_]+)%(")
          or line:match("^local function ([%w_]+)%(")
        if func_name then
          current_func.name = func_name
          current_func.line = line
          functions[func_name] = current_func
          current_func = nil
        end
      end
    end
  end

  return {
    module = module_info,
    functions = functions,
  }
end

-- Generate vimdoc from parsed data
local function generate_vimdoc_content(parsed_files)
  local lines = {}

  -- Get module info from main file
  local main_module = parsed_files["lua/terrareg/init.lua"]
  local module_name = main_module and main_module.module.name or "terrareg"
  local description = main_module and main_module.module.description or "A Neovim plugin"
  local author = main_module and main_module.module.author or "Unknown"
  local license = main_module and main_module.module.license or "GPL-3.0"

  -- Header
  table.insert(lines, "*" .. module_name .. ".txt*  " .. description)
  table.insert(lines, "")
  table.insert(lines, "Author: " .. author)
  table.insert(lines, "License: " .. license)
  table.insert(lines, "")

  -- Table of contents
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "CONTENTS                                                    *" .. module_name .. "-contents*"
  )
  table.insert(lines, "")
  table.insert(
    lines,
    "1. Introduction ............................ |" .. module_name .. "-introduction|"
  )
  table.insert(
    lines,
    "2. Installation ............................ |" .. module_name .. "-installation|"
  )
  table.insert(
    lines,
    "3. Configuration ........................... |" .. module_name .. "-configuration|"
  )
  table.insert(lines, "4. Usage ................................... |" .. module_name .. "-usage|")
  table.insert(lines, "5. API ..................................... |" .. module_name .. "-api|")
  table.insert(
    lines,
    "6. License ................................. |" .. module_name .. "-license|"
  )
  table.insert(lines, "")

  -- Introduction
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "INTRODUCTION                                            *" .. module_name .. "-introduction*"
  )
  table.insert(lines, "")
  table.insert(lines, description .. ".")
  table.insert(lines, "")

  -- Installation
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "INSTALLATION                                            *" .. module_name .. "-installation*"
  )
  table.insert(lines, "")
  table.insert(lines, "Using lazy.nvim: >")
  table.insert(lines, "    {")
  table.insert(lines, '      "remoterabbit/' .. module_name .. '",')
  table.insert(lines, "      config = function()")
  table.insert(lines, '        require("' .. module_name .. '").setup({})')
  table.insert(lines, "      end,")
  table.insert(lines, "    }")
  table.insert(lines, "<")
  table.insert(lines, "")

  -- Configuration (extract from config table)
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "CONFIGURATION                                          *" .. module_name .. "-configuration*"
  )
  table.insert(lines, "")
  table.insert(lines, "Default configuration: >")
  table.insert(lines, '    require("' .. module_name .. '").setup({')

  -- Try to extract config from parsed data
  if main_module and main_module.functions.setup then
    table.insert(lines, "      -- See API documentation for setup() function")
  end

  table.insert(lines, "    })")
  table.insert(lines, "<")
  table.insert(lines, "")

  -- Usage
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "USAGE                                                        *" .. module_name .. "-usage*"
  )
  table.insert(lines, "")

  -- Extract usage examples from functions
  local has_usage = false
  for _, data in pairs(parsed_files) do
    for func_name, func_data in pairs(data.functions) do
      if #func_data.usage > 0 then
        table.insert(lines, func_name .. ": >")
        for _, usage in ipairs(func_data.usage) do
          table.insert(lines, "    " .. usage)
        end
        table.insert(lines, "<")
        table.insert(lines, "")
        has_usage = true
      end
    end
  end

  if not has_usage then
    table.insert(lines, "[Add usage instructions here]")
    table.insert(lines, "")
  end

  -- API
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "API                                                            *" .. module_name .. "-api*"
  )
  table.insert(lines, "")

  -- Generate API docs from parsed functions
  for _, data in pairs(parsed_files) do
    for func_name, func_data in pairs(data.functions) do
      if func_name ~= "new" and not func_name:match("^_") then -- Skip private functions
        -- Function signature
        local params_str = ""
        if #func_data.params > 0 then
          local param_names = {}
          for _, param in ipairs(func_data.params) do
            table.insert(param_names, "{" .. param.name .. "}")
          end
          params_str = table.concat(param_names, ", ")
        end

        table.insert(
          lines,
          func_name
            .. "("
            .. params_str
            .. ")                                          *"
            .. module_name
            .. "."
            .. func_name
            .. "()*"
        )
        table.insert(lines, "    " .. (func_data.description or "No description available"))
        table.insert(lines, "")

        -- Parameters
        if #func_data.params > 0 then
          table.insert(lines, "    Parameters: ~")
          for _, param in ipairs(func_data.params) do
            table.insert(lines, "        {" .. param.name .. "} " .. param.desc)
          end
          table.insert(lines, "")
        end

        -- Returns
        if #func_data.returns > 0 then
          table.insert(lines, "    Returns: ~")
          for _, ret in ipairs(func_data.returns) do
            table.insert(lines, "        " .. ret)
          end
          table.insert(lines, "")
        end
      end
    end
  end

  -- License
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "LICENSE                                                    *" .. module_name .. "-license*"
  )
  table.insert(lines, "")
  table.insert(lines, license .. " License")
  table.insert(lines, "")
  table.insert(lines, "vim:tw=78:ts=8:ft=help:norl:")

  return table.concat(lines, "\n")
end

-- Main function to generate dynamic vimdoc
local function generate_dynamic_vimdoc()
  local lua_files = {
    "lua/terrareg/init.lua",
    "plugin/terrareg.lua",
  }

  local parsed_files = {}

  -- Parse all Lua files
  for _, filepath in ipairs(lua_files) do
    if vim.fn.filereadable(filepath) == 1 then
      parsed_files[filepath] = parse_lua_file(filepath)
    end
  end

  -- Generate vimdoc content
  local content = generate_vimdoc_content(parsed_files)

  -- Ensure doc directory exists
  vim.fn.mkdir("doc", "p")

  -- Write the file
  local file = io.open("doc/terrareg.txt", "w")
  if file then
    file:write(content)
    file:close()
    print("✅ Generated dynamic doc/terrareg.txt")
    return true
  else
    print("❌ Failed to write doc/terrareg.txt")
    return false
  end
end

M.generate = generate_dynamic_vimdoc
M.parse_lua_file = parse_lua_file
M.generate_vimdoc_content = generate_vimdoc_content

-- If called directly
if ... == nil then
  generate_dynamic_vimdoc()
end

return M
