--- Clipboard operations for terrareg.nvim
-- @module terrareg.clipboard

local M = {}

--- Copy text to system clipboard
-- @param text string Text to copy
-- @param register string|nil Vim register to use (default: '+')
function M.copy_to_clipboard(text, register)
  register = register or "+"

  -- Set the register
  vim.fn.setreg(register, text)

  -- Also try to set system clipboard directly
  if vim.fn.has("clipboard") == 1 then
    vim.fn.setreg("+", text)
    vim.fn.setreg("*", text)
  end

  vim.notify(string.format("Copied %d characters to clipboard", #text), vim.log.levels.INFO)
end

--- Copy example code from documentation
-- @param doc_data table Documentation data
-- @param example_index number|nil Index of example to copy (default: 1)
function M.copy_example(doc_data, example_index)
  if not doc_data.examples or #doc_data.examples == 0 then
    vim.notify("No examples available to copy", vim.log.levels.WARN)
    return
  end

  example_index = example_index or 1
  if example_index > #doc_data.examples then
    vim.notify(
      string.format(
        "Example %d not found (only %d examples available)",
        example_index,
        #doc_data.examples
      ),
      vim.log.levels.WARN
    )
    return
  end

  local example = doc_data.examples[example_index]
  M.copy_to_clipboard(example)

  if #doc_data.examples > 1 then
    vim.notify(
      string.format("Copied example %d of %d", example_index, #doc_data.examples),
      vim.log.levels.INFO
    )
  else
    vim.notify("Copied example code", vim.log.levels.INFO)
  end
end

--- Copy argument list as template
-- @param doc_data table Documentation data
-- @param resource_name string|nil Resource name for template
function M.copy_argument_template(doc_data, resource_name)
  if not doc_data.arguments or #doc_data.arguments == 0 then
    vim.notify("No arguments available to copy", vim.log.levels.WARN)
    return
  end

  resource_name = resource_name or "resource_name"
  local resource_type = doc_data.title and doc_data.title:match("^([^:]+)") or "aws_resource"

  local template_lines = {
    string.format('resource "%s" "%s" {', resource_type, resource_name),
  }

  -- Add required arguments first
  for _, arg in ipairs(doc_data.arguments) do
    if arg.required == "Required" then
      local comment = string.format("  # %s", arg.description or "")
      if #comment > 80 then
        comment = comment:sub(1, 77) .. "..."
      end
      table.insert(template_lines, comment)
      table.insert(template_lines, string.format("  %s = ", arg.name))
      table.insert(template_lines, "")
    end
  end

  -- Add optional arguments as comments
  table.insert(template_lines, "  # Optional arguments:")
  for _, arg in ipairs(doc_data.arguments) do
    if arg.required ~= "Required" then
      local default_comment = arg.default
          and arg.default ~= ""
          and string.format(" (default: %s)", arg.default)
        or ""
      table.insert(
        template_lines,
        string.format("  # %s = %s%s", arg.name, "value", default_comment)
      )
    end
  end

  table.insert(template_lines, "}")

  local template = table.concat(template_lines, "\n")
  M.copy_to_clipboard(template)

  vim.notify("Copied argument template", vim.log.levels.INFO)
end

--- Copy documentation URL
-- @param doc_data table Documentation data
function M.copy_url(doc_data)
  if not doc_data.url then
    vim.notify("No URL available to copy", vim.log.levels.WARN)
    return
  end

  M.copy_to_clipboard(doc_data.url)
  vim.notify("Copied documentation URL", vim.log.levels.INFO)
end

--- Copy specific argument information
-- @param doc_data table Documentation data
-- @param arg_name string Argument name
function M.copy_argument_info(doc_data, arg_name)
  if not doc_data.arguments then
    vim.notify("No arguments available", vim.log.levels.WARN)
    return
  end

  local found_arg = nil
  for _, arg in ipairs(doc_data.arguments) do
    if arg.name == arg_name then
      found_arg = arg
      break
    end
  end

  if not found_arg then
    vim.notify(string.format("Argument '%s' not found", arg_name), vim.log.levels.WARN)
    return
  end

  local info_lines = {
    string.format("Argument: %s", found_arg.name),
    string.format("Required: %s", found_arg.required or "Unknown"),
  }

  if found_arg.default and found_arg.default ~= "" then
    table.insert(info_lines, string.format("Default: %s", found_arg.default))
  end

  if found_arg.forces_new then
    table.insert(info_lines, "Forces new resource: Yes")
  end

  table.insert(info_lines, "")
  table.insert(
    info_lines,
    string.format("Description: %s", found_arg.description or "No description available")
  )

  local info_text = table.concat(info_lines, "\n")
  M.copy_to_clipboard(info_text)

  vim.notify(string.format("Copied information for argument '%s'", arg_name), vim.log.levels.INFO)
end

--- Interactive copy menu
-- @param doc_data table Documentation data
function M.show_copy_menu(doc_data)
  local choices = {
    "1. Copy example code",
    "2. Copy argument template",
    "3. Copy documentation URL",
    "4. Copy argument info",
  }

  if doc_data.examples and #doc_data.examples > 1 then
    for i = 2, #doc_data.examples do
      table.insert(choices, string.format("%d. Copy example %d", #choices + 1, i))
    end
  end

  vim.ui.select(choices, {
    prompt = "What would you like to copy?",
    format_item = function(item)
      return item
    end,
  }, function(choice, index)
    if not choice then
      return
    end

    if index == 1 then
      M.copy_example(doc_data, 1)
    elseif index == 2 then
      M.copy_argument_template(doc_data)
    elseif index == 3 then
      M.copy_url(doc_data)
    elseif index == 4 then
      -- Prompt for argument name
      vim.ui.input({
        prompt = "Argument name: ",
      }, function(arg_name)
        if arg_name and arg_name ~= "" then
          M.copy_argument_info(doc_data, arg_name)
        end
      end)
    else
      -- Handle additional examples
      local example_index = index - 3
      M.copy_example(doc_data, example_index)
    end
  end)
end

return M
