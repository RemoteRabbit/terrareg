-- Extract usage examples from test files and source code
-- This script finds and formats examples for documentation

local M = {}

-- Find and parse test files for examples
local function find_test_files()
  local test_files = {}

  -- Common test directories
  local test_dirs = { "test/", "tests/", "spec/" }

  for _, dir in ipairs(test_dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local files = vim.fn.globpath(dir, "**/*.lua", false, true)
      for _, file in ipairs(files) do
        table.insert(test_files, file)
      end
    end
  end

  return test_files
end

-- Extract examples from a test file
local function extract_examples_from_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local examples = {}
  local current_test = nil
  local in_example = false
  local example_lines = {}

  for line in content:gmatch("[^\r\n]+") do
    -- Test block detection
    if line:match("describe%s*%(") or line:match("it%s*%(") or line:match("test%s*%(") then
      local test_name = line:match("[\"']([^\"']+)[\"']")
      if test_name then
        current_test = test_name
      end
    end

    -- Example code detection
    if line:match("require%s*%(%s*['\"]terrareg['\"]") then
      in_example = true
      table.insert(example_lines, line)
    elseif in_example then
      if line:match("^%s*end") or line:match("^%s*$") then
        if #example_lines > 0 then
          table.insert(examples, {
            name = current_test or "Usage Example",
            code = table.concat(example_lines, "\n"),
            file = filepath,
          })
          example_lines = {}
          in_example = false
        end
      else
        table.insert(example_lines, line)
      end
    end

    -- Look for setup examples
    if line:match("%.setup%s*%(") then
      table.insert(examples, {
        name = "Setup Configuration",
        code = line,
        file = filepath,
      })
    end
  end

  return examples
end

-- Extract examples from source code comments
local function extract_examples_from_source(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local examples = {}
  local in_usage = false
  local usage_lines = {}
  local current_function = nil

  for line in content:gmatch("[^\r\n]+") do
    -- Function detection
    if line:match("^function [%w%.]-%.?([%w_]+)%(") or line:match("^local function ([%w_]+)%(") then
      current_function = line:match("^function [%w%.]-%.?([%w_]+)%(")
        or line:match("^local function ([%w_]+)%(")
    end

    -- Usage example detection
    if line:match("^%-%- @usage") then
      in_usage = true
      local usage_code = line:match("^%-%- @usage (.+)")
      if usage_code then
        table.insert(usage_lines, usage_code)
      end
    elseif line:match("^%-%-") and in_usage then
      local usage_code = line:match("^%-%- (.+)")
      if usage_code and usage_code ~= "" then
        table.insert(usage_lines, usage_code)
      else
        -- End of usage block
        if #usage_lines > 0 then
          table.insert(examples, {
            name = current_function and (current_function .. " usage") or "Usage Example",
            code = table.concat(usage_lines, "\n"),
            file = filepath,
            function_name = current_function,
          })
          usage_lines = {}
        end
        in_usage = false
      end
    elseif not line:match("^%-%-") and in_usage then
      -- End of comment block
      if #usage_lines > 0 then
        table.insert(examples, {
          name = current_function and (current_function .. " usage") or "Usage Example",
          code = table.concat(usage_lines, "\n"),
          file = filepath,
          function_name = current_function,
        })
        usage_lines = {}
      end
      in_usage = false
    end
  end

  return examples
end

-- Generate examples documentation
local function generate_examples_docs()
  local all_examples = {}

  -- Extract from source files
  local source_files = {
    "lua/terrareg/init.lua",
    "plugin/terrareg.lua",
  }

  for _, filepath in ipairs(source_files) do
    if vim.fn.filereadable(filepath) == 1 then
      local examples = extract_examples_from_source(filepath)
      for _, example in ipairs(examples) do
        table.insert(all_examples, example)
      end
    end
  end

  -- Extract from test files
  local test_files = find_test_files()
  for _, filepath in ipairs(test_files) do
    local examples = extract_examples_from_file(filepath)
    for _, example in ipairs(examples) do
      table.insert(all_examples, example)
    end
  end

  -- Generate markdown
  local lines = {}
  table.insert(lines, "# Usage Examples")
  table.insert(lines, "")
  table.insert(
    lines,
    "This page contains automatically extracted usage examples from the codebase."
  )
  table.insert(lines, "")

  if #all_examples == 0 then
    table.insert(lines, "## Basic Setup")
    table.insert(lines, "")
    table.insert(lines, "```lua")
    table.insert(lines, "require('terrareg').setup({")
    table.insert(lines, "  option1 = true,")
    table.insert(lines, "  option2 = 'custom_value',")
    table.insert(lines, "  debug = false")
    table.insert(lines, "})")
    table.insert(lines, "```")
    table.insert(lines, "")
    table.insert(lines, "## Get Configuration")
    table.insert(lines, "")
    table.insert(lines, "```lua")
    table.insert(lines, "local config = require('terrareg').get_config()")
    table.insert(lines, "print(vim.inspect(config))")
    table.insert(lines, "```")
  else
    for _, example in ipairs(all_examples) do
      table.insert(lines, "## " .. example.name)
      table.insert(lines, "")
      if example.file then
        table.insert(lines, "*From: " .. example.file .. "*")
        table.insert(lines, "")
      end
      table.insert(lines, "```lua")
      table.insert(lines, example.code)
      table.insert(lines, "```")
      table.insert(lines, "")
    end
  end

  -- Write file
  vim.fn.mkdir("docs/generated", "p")

  local file = io.open("docs/generated/examples.md", "w")
  if file then
    file:write(table.concat(lines, "\n"))
    file:close()
    print("✅ Generated docs/generated/examples.md")
    return true
  else
    print("❌ Failed to write docs/generated/examples.md")
    return false
  end
end

M.generate = generate_examples_docs
M.extract_examples_from_file = extract_examples_from_file
M.extract_examples_from_source = extract_examples_from_source

-- If called directly
if ... == nil then
  generate_examples_docs()
end

return M
