--- LSP integration for terrareg.nvim
-- @module terrareg.lsp

local M = {}

-- LSP state
M.state = {
  enabled = false,
  completion_cache = {},
  last_cache_update = 0,
}

--- Setup LSP integration
-- @param opts table Configuration options
function M.setup(opts)
  opts = opts or {}

  M.state.enabled = opts.enabled ~= false -- Default to enabled

  if M.state.enabled then
    M.setup_completion()
    M.setup_hover()
    M.setup_validation()
  end
end

--- Setup auto-completion for Terraform files
function M.setup_completion()
  -- Register completion source
  local has_cmp, cmp = pcall(require, "cmp")
  if has_cmp then
    local source = {}

    function source.new()
      return setmetatable({}, { __index = source })
    end

    function source:is_available()
      return vim.bo.filetype == "terraform" or vim.bo.filetype == "hcl"
    end

    function source:get_trigger_characters()
      return { '"', "_", "-" }
    end

    function source:complete(params, callback)
      M.get_completions(params, callback)
    end

    cmp.register_source("terrareg", source)
  end
end

--- Get completion items
-- @param params table LSP completion parameters
-- @param callback function Callback with completion items
function M.get_completions(params, callback)
  local line = params.context.cursor_before_line
  local items = {}

  -- Check if we're in a resource or data block
  local resource_match = line:match('resource%s+"([^"]*)"?')
  local data_match = line:match('data%s+"([^"]*)"?')

  if resource_match or data_match then
    -- Complete resource/data source names
    local query = resource_match or data_match or ""
    local resource_type = resource_match and "resource" or "data"

    -- Get matching resources from all providers
    local providers = require("terrareg.providers")
    local all_resources = providers.get_all_resources()

    for _, resource in ipairs(all_resources) do
      if resource.type == resource_type and resource.name:find(query, 1, true) then
        table.insert(items, {
          label = resource.name,
          kind = 21, -- Module
          detail = resource.category .. " - " .. resource.description,
          documentation = {
            kind = "markdown",
            value = string.format(
              "**%s**\n\n%s\n\nProvider: %s",
              resource.name,
              resource.description,
              resource.provider or "aws"
            ),
          },
          insertText = resource.name,
        })
      end
    end
  else
    -- Check if we're inside a resource block for argument completion
    local block_start =
      M.find_current_resource_block(params.context.bufnr, params.context.cursor.line)
    if block_start then
      M.get_argument_completions(block_start, query or "", callback)
      return
    end
  end

  callback(items)
end

--- Find the current resource block
-- @param bufnr number Buffer number
-- @param line_num number Current line number
-- @return table|nil Resource block info
function M.find_current_resource_block(bufnr, line_num)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_num + 10, false)

  -- Look backwards for resource declaration
  for i = line_num, 1, -1 do
    local line = lines[i]
    if line then
      local resource_type, resource_name = line:match('(resource)%s+"([^"]+)"%s+"[^"]*"%s*{')
      if not resource_type then
        resource_type, resource_name = line:match('(data)%s+"([^"]+)"%s+"[^"]*"%s*{')
      end

      if resource_type and resource_name then
        return {
          type = resource_type,
          name = resource_name,
          line = i,
        }
      end
    end
  end

  return nil
end

--- Get argument completions for a specific resource
-- @param block_info table Resource block information
-- @param query string Current query
-- @param callback function Callback with completion items
function M.get_argument_completions(block_info, query, callback)
  local cache_key = block_info.type .. "_" .. block_info.name

  -- Check cache first
  if M.state.completion_cache[cache_key] then
    local cached = M.state.completion_cache[cache_key]
    local filtered_items = {}

    for _, item in ipairs(cached.items) do
      if item.label:find(query, 1, true) then
        table.insert(filtered_items, item)
      end
    end

    callback(filtered_items)
    return
  end

  -- Fetch documentation and extract arguments
  require("terrareg.docs").fetch_documentation(
    block_info.type,
    block_info.name,
    nil,
    function(success, doc_data, error)
      if success and doc_data.arguments then
        local items = {}

        for _, arg in ipairs(doc_data.arguments) do
          local detail = arg.required or "Optional"
          if arg.default and arg.default ~= "" then
            detail = detail .. " (default: " .. arg.default .. ")"
          end
          if arg.forces_new then
            detail = detail .. " [Forces new resource]"
          end

          table.insert(items, {
            label = arg.name,
            kind = 5, -- Field
            detail = detail,
            documentation = {
              kind = "markdown",
              value = string.format(
                "**%s**\n\n%s",
                arg.name,
                arg.description or "No description available"
              ),
            },
            insertText = arg.name .. " = ",
          })
        end

        -- Cache the results
        M.state.completion_cache[cache_key] = {
          items = items,
          timestamp = os.time(),
        }

        -- Filter by query
        local filtered_items = {}
        for _, item in ipairs(items) do
          if item.label:find(query, 1, true) then
            table.insert(filtered_items, item)
          end
        end

        callback(filtered_items)
      else
        callback({})
      end
    end
  )
end

--- Setup hover provider
function M.setup_hover()
  -- Hook into LSP hover
  local original_hover = vim.lsp.buf.hover

  vim.lsp.buf.hover = function()
    if vim.bo.filetype == "terraform" or vim.bo.filetype == "hcl" then
      local word = vim.fn.expand("<cword>")

      -- Check if it's a resource name
      if word:match("^aws_") or word:match("^azurerm_") or word:match("^google_") then
        local resource_type = M.detect_resource_type_from_context()
        if resource_type then
          M.show_hover_documentation(resource_type, word)
          return
        end
      end
    end

    -- Fall back to original hover
    original_hover()
  end
end

--- Detect resource type from cursor context
-- @return string|nil "resource" or "data"
function M.detect_resource_type_from_context()
  local line = vim.api.nvim_get_current_line()

  if line:match("resource%s+") then
    return "resource"
  elseif line:match("data%s+") then
    return "data"
  end

  -- Look at previous lines
  local lines =
    vim.api.nvim_buf_get_lines(0, math.max(0, vim.fn.line(".") - 5), vim.fn.line("."), false)
  for _, prev_line in ipairs(lines) do
    if prev_line:match("resource%s+") then
      return "resource"
    elseif prev_line:match("data%s+") then
      return "data"
    end
  end

  return nil
end

--- Show hover documentation for resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
function M.show_hover_documentation(resource_type, resource_name)
  require("terrareg.docs").fetch_documentation(
    resource_type,
    resource_name,
    nil,
    function(success, doc_data, error)
      vim.schedule(function()
        if success then
          local hover_content = M.create_hover_content(doc_data)

          -- Show in floating window
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, hover_content)

          local win = vim.api.nvim_open_win(buf, false, {
            relative = "cursor",
            width = 60,
            height = math.min(#hover_content, 15),
            row = 1,
            col = 0,
            style = "minimal",
            border = "rounded",
          })

          -- Auto-close after 5 seconds or on cursor move
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 5000)
        else
          vim.notify("Hover documentation not available", vim.log.levels.WARN)
        end
      end)
    end
  )
end

--- Create hover content
-- @param doc_data table Documentation data
-- @return table Lines for hover display
function M.create_hover_content(doc_data)
  local lines = {}

  table.insert(lines, "📖 " .. (doc_data.title or "Unknown"))
  table.insert(lines, "")

  if doc_data.description then
    local short_desc = doc_data.description
    if #short_desc > 100 then
      short_desc = short_desc:sub(1, 97) .. "..."
    end
    table.insert(lines, short_desc)
    table.insert(lines, "")
  end

  -- Show key arguments
  if doc_data.arguments then
    local required_args = {}
    for _, arg in ipairs(doc_data.arguments) do
      if arg.required == "Required" then
        table.insert(required_args, arg.name)
      end
    end

    if #required_args > 0 then
      table.insert(lines, "Required: " .. table.concat(required_args, ", "))
      table.insert(lines, "")
    end
  end

  table.insert(lines, "Press gd for full documentation")

  return lines
end

--- Setup code validation
function M.setup_validation()
  -- Create autocmd for Terraform file validation
  vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
    pattern = { "*.tf", "*.hcl" },
    callback = function(args)
      M.validate_terraform_file(args.buf)
    end,
    group = vim.api.nvim_create_augroup("TerraregValidation", { clear = true }),
  })
end

--- Validate Terraform file against documentation
-- @param bufnr number Buffer number
function M.validate_terraform_file(bufnr)
  if not M.state.enabled then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local diagnostics = {}

  for line_num, line in ipairs(lines) do
    -- Check for resource/data declarations
    local resource_type, resource_name = line:match('(resource)%s+"([^"]+)"')
    if not resource_type then
      resource_type, resource_name = line:match('(data)%s+"([^"]+)"')
    end

    if resource_type and resource_name then
      -- Validate this resource asynchronously
      M.validate_resource_block(bufnr, line_num - 1, resource_type, resource_name, lines)
    end
  end
end

--- Validate a specific resource block
-- @param bufnr number Buffer number
-- @param start_line number Starting line of resource block
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
-- @param lines table All buffer lines
function M.validate_resource_block(bufnr, start_line, resource_type, resource_name, lines)
  require("terrareg.docs").fetch_documentation(
    resource_type,
    resource_name,
    nil,
    function(success, doc_data, error)
      if not success or not doc_data.arguments then
        return
      end

      vim.schedule(function()
        local diagnostics = M.check_arguments(bufnr, start_line, lines, doc_data.arguments)

        -- Set diagnostics
        if #diagnostics > 0 then
          vim.diagnostic.set(
            vim.api.nvim_create_namespace("terrareg_validation"),
            bufnr,
            diagnostics,
            {}
          )
        end
      end)
    end
  )
end

--- Check arguments in resource block
-- @param bufnr number Buffer number
-- @param start_line number Starting line of resource block
-- @param lines table All buffer lines
-- @param documented_args table Arguments from documentation
-- @return table List of diagnostics
function M.check_arguments(bufnr, start_line, lines, documented_args)
  local diagnostics = {}
  local used_args = {}
  local required_args = {}

  -- Build lookup tables
  local arg_lookup = {}
  for _, arg in ipairs(documented_args) do
    arg_lookup[arg.name] = arg
    if arg.required == "Required" then
      table.insert(required_args, arg.name)
    end
  end

  -- Find the resource block
  local in_block = false
  local brace_count = 0

  for i = start_line + 1, #lines do
    local line = lines[i]

    if line:match("{") then
      in_block = true
      brace_count = brace_count + (select(2, line:gsub("{", "")) or 0)
    end

    if in_block then
      brace_count = brace_count - (select(2, line:gsub("}", "")) or 0)

      -- Check for argument usage
      local arg_name = line:match("^%s*([a-zA-Z_][a-zA-Z0-9_]*)%s*=")
      if arg_name then
        used_args[arg_name] = true

        -- Check if argument is documented
        if not arg_lookup[arg_name] then
          table.insert(diagnostics, {
            lnum = i - 1,
            col = line:find(arg_name) - 1,
            end_col = line:find(arg_name) + #arg_name - 1,
            severity = vim.diagnostic.severity.WARN,
            message = string.format("Argument '%s' is not documented for this resource", arg_name),
            source = "terrareg",
          })
        end
      end

      if brace_count <= 0 then
        break
      end
    end
  end

  -- Check for missing required arguments
  for _, req_arg in ipairs(required_args) do
    if not used_args[req_arg] then
      table.insert(diagnostics, {
        lnum = start_line,
        col = 0,
        end_col = 0,
        severity = vim.diagnostic.severity.ERROR,
        message = string.format("Missing required argument: '%s'", req_arg),
        source = "terrareg",
      })
    end
  end

  return diagnostics
end

--- Setup hover provider
function M.setup_hover()
  -- This would integrate with existing LSP hover
  -- Implementation depends on the specific LSP setup
end

--- Insert argument template at cursor
-- @param resource_type string "resource" or "data"
-- @param resource_name string Resource name
function M.insert_argument_template(resource_type, resource_name)
  require("terrareg.docs").fetch_documentation(
    resource_type,
    resource_name,
    nil,
    function(success, doc_data, error)
      vim.schedule(function()
        if success then
          require("terrareg.clipboard").copy_argument_template(doc_data, "example")

          -- Also insert at cursor
          local template_lines = M.generate_argument_template(doc_data)
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, template_lines)

          vim.notify("Inserted argument template", vim.log.levels.INFO)
        else
          vim.notify(
            "Failed to fetch arguments: " .. (error or "unknown error"),
            vim.log.levels.ERROR
          )
        end
      end)
    end
  )
end

--- Generate argument template lines
-- @param doc_data table Documentation data
-- @return table Lines for template
function M.generate_argument_template(doc_data)
  local lines = {}

  if not doc_data.arguments then
    return lines
  end

  -- Add required arguments
  for _, arg in ipairs(doc_data.arguments) do
    if arg.required == "Required" then
      table.insert(lines, string.format("  %s = ", arg.name))
    end
  end

  -- Add commented optional arguments
  for _, arg in ipairs(doc_data.arguments) do
    if arg.required ~= "Required" then
      local default_hint = arg.default and arg.default ~= "" and " # default: " .. arg.default or ""
      table.insert(lines, string.format("  # %s = %s", arg.name, default_hint))
    end
  end

  return lines
end

return M
