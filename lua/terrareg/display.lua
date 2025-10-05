--- Display module for terrareg.nvim
-- @module terrareg.display

local M = {}
local ui = require("terrareg.ui")

--- Wrap text at specified width
-- @param text string Text to wrap
-- @param width number Maximum line width
-- @return string Wrapped text

local formatting = require("terrareg.formatting")
local wrap_text = formatting.wrap_text

--- Pad string to specific width, accounting for Unicode display width
-- @param str string String to pad
-- @param width number Target display width
-- @return string Padded string
local pad_string = formatting.pad_string

--- Format arguments in modern card-based layout
-- @param arguments table List of arguments
-- @param width number Available width for the layout
-- @return table Lines representing the formatted arguments
local function format_arguments_modern(arguments, width)
  if not arguments or #arguments == 0 then
    return {}
  end

  local lines = {}

  -- Sort arguments: required first, then optional
  local sorted_args = {}
  local required_args = {}
  local optional_args = {}

  for _, arg in ipairs(arguments) do
    if arg.required == "Required" then
      table.insert(required_args, arg)
    else
      table.insert(optional_args, arg)
    end
  end

  -- Combine sorted lists
  for _, arg in ipairs(required_args) do
    table.insert(sorted_args, arg)
  end
  for _, arg in ipairs(optional_args) do
    table.insert(sorted_args, arg)
  end

  local card_width = math.min(100, width - 4)

  for i, arg in ipairs(sorted_args) do
    -- Card header with argument name and status
    local status_icon = arg.required == "Required" and ui.icons.required or ui.icons.optional
    local status_text = arg.required == "Required" and "REQUIRED" or "OPTIONAL"
    local forces_indicator = arg.forces_new and " " .. ui.icons.forces_new .. " FORCES NEW" or ""

    -- Card border top
    table.insert(lines, "╭" .. string.rep("─", card_width - 2) .. "╮")

    -- Argument name line with status
    local name_line =
      string.format("│ %s %s %s%s", status_icon, arg.name, status_text, forces_indicator)
    local padding_needed = card_width - #name_line - 1
    if padding_needed > 0 then
      name_line = name_line .. string.rep(" ", padding_needed)
    end
    name_line = name_line .. "│"
    table.insert(lines, name_line)

    -- Type information if available
    if arg.type then
      local type_line = string.format("│ %s Type: %s", ui.icons.info, arg.type)
      local padding_needed = card_width - #type_line - 1
      if padding_needed > 0 then
        type_line = type_line .. string.rep(" ", padding_needed)
      end
      type_line = type_line .. "│"
      table.insert(lines, type_line)
    end

    -- Default value if present
    if arg.default and arg.default ~= "" then
      local default_line = string.format("│ %s Default: %s", ui.icons.diamond, arg.default)
      local padding_needed = card_width - #default_line - 1
      if padding_needed > 0 then
        default_line = default_line .. string.rep(" ", padding_needed)
      end
      default_line = default_line .. "│"
      table.insert(lines, default_line)
    end

    -- Separator line for description
    if arg.description then
      table.insert(lines, "├" .. string.rep("─", card_width - 2) .. "┤")

      -- Description with proper wrapping
      local desc_width = card_width - 4
      local description = arg.description or ""
      local wrapped_desc = wrap_text(description, desc_width)

      for line in wrapped_desc:gmatch("[^\n]+") do
        local desc_line = string.format("│ %s", line)
        local padding_needed = card_width - #desc_line - 1
        if padding_needed > 0 then
          desc_line = desc_line .. string.rep(" ", padding_needed)
        end
        desc_line = desc_line .. "│"
        table.insert(lines, desc_line)
      end
    end

    -- Card border bottom
    table.insert(lines, "╰" .. string.rep("─", card_width - 2) .. "╯")

    -- Add spacing between cards
    if i < #sorted_args then
      table.insert(lines, "")
    end
  end

  return lines
end

--- Create a copy-friendly argument block
-- @param arg table Argument data
-- @return table Lines for copy-friendly format
local function format_argument_copyable(arg)
  local lines = {}

  -- Terraform-style comment block
  table.insert(
    lines,
    string.format("  # %s (%s)", arg.name, arg.required == "Required" and "required" or "optional")
  )

  if arg.description then
    local wrapped_desc = wrap_text(arg.description, 76)
    for line in wrapped_desc:gmatch("[^\n]+") do
      table.insert(lines, "  # " .. line)
    end
  end

  if arg.type then
    table.insert(lines, string.format("  # Type: %s", arg.type))
  end

  if arg.default and arg.default ~= "" then
    table.insert(lines, string.format("  # Default: %s", arg.default))
  end

  if arg.forces_new then
    table.insert(lines, "  # ⚠️  Changing this forces a new resource")
  end

  -- Actual argument line
  local value = arg.default or "null"
  if arg.type and arg.type:lower():find("string") then
    value = '""'
  elseif arg.type and arg.type:lower():find("bool") then
    value = "false"
  elseif arg.type and (arg.type:lower():find("list") or arg.type:lower():find("array")) then
    value = "[]"
  elseif arg.type and (arg.type:lower():find("map") or arg.type:lower():find("object")) then
    value = "{}"
  end

  table.insert(lines, string.format("  %s = %s", arg.name, value))

  return lines
end

--- Create documentation buffer content
-- @param doc_data table Documentation data
-- @return table Lines of content for the buffer
local function create_documentation_content(doc_data)
  local lines = {}
  local window_width = 140 -- Much wider for spacious layout

  -- Enhanced header with modern styling
  local header_line = string.rep("═", window_width)
  table.insert(lines, header_line)
  table.insert(lines, "")

  -- Title with resource type icon
  local resource_icon = ui.icons.resource
  if doc_data.resource_type == "data" then
    resource_icon = ui.icons.data_source
  end

  table.insert(
    lines,
    string.format("%s %s TERRAFORM DOCUMENTATION", resource_icon, ui.icons.external_link)
  )
  table.insert(lines, "")
  table.insert(lines, header_line)
  table.insert(lines, "")

  -- Enhanced resource information with breadcrumb
  local breadcrumb_path = {}
  if doc_data.provider then
    table.insert(breadcrumb_path, doc_data.provider)
  end
  if doc_data.resource_type then
    table.insert(breadcrumb_path, doc_data.resource_type)
  end
  if doc_data.resource_name then
    table.insert(breadcrumb_path, doc_data.resource_name)
  end

  if #breadcrumb_path > 0 then
    table.insert(lines, ui.create_breadcrumb(breadcrumb_path))
    table.insert(lines, "")
  end

  table.insert(lines, string.format("%s Resource: %s", ui.icons.info, doc_data.title or "Unknown"))
  table.insert(
    lines,
    string.format("%s Source: %s", ui.icons.provider, doc_data.source or "unknown")
  )
  if doc_data.url then
    table.insert(lines, string.format("%s URL: %s", ui.icons.external_link, doc_data.url))
  end
  table.insert(lines, "")
  table.insert(lines, "")

  -- Description with enhanced styling
  if doc_data.description then
    table.insert(lines, string.format("%s Description:", ui.icons.info))
    table.insert(lines, "")
    local wrapped_desc = wrap_text(doc_data.description, window_width - 8)
    for line in wrapped_desc:gmatch("[^\n]+") do
      table.insert(lines, "    " .. line) -- Indent for readability
    end
    table.insert(lines, "")
    table.insert(lines, "")
  end

  -- Modern arguments display with enhanced readability
  if doc_data.arguments and #doc_data.arguments > 0 then
    -- Count required vs optional
    local required_count = 0
    local optional_count = 0
    for _, arg in ipairs(doc_data.arguments) do
      if arg.required == "Required" then
        required_count = required_count + 1
      else
        optional_count = optional_count + 1
      end
    end

    table.insert(
      lines,
      string.format(
        "%s Arguments (%s %d required, %s %d optional):",
        ui.icons.diamond,
        ui.icons.required,
        required_count,
        ui.icons.optional,
        optional_count
      )
    )
    table.insert(lines, "")

    -- Add quick copy instruction
    table.insert(
      lines,
      string.format(
        "%s Tip: Press 'c' to copy argument template, 'C' to copy individual arguments",
        ui.icons.copy
      )
    )
    table.insert(lines, "")

    local arg_lines = format_arguments_modern(doc_data.arguments, window_width)
    for _, line in ipairs(arg_lines) do
      table.insert(lines, line)
    end
    table.insert(lines, "")
    table.insert(lines, "")
  end

  -- Modern examples display with copy-friendly formatting
  if doc_data.examples and #doc_data.examples > 0 then
    table.insert(lines, string.format("%s Example Usage:", ui.icons.copy))
    table.insert(lines, "")
    table.insert(
      lines,
      string.format("%s Tip: Press 'x' to copy selected example to clipboard", ui.icons.info)
    )
    table.insert(lines, "")

    for i, example in ipairs(doc_data.examples) do
      -- Example card header
      local example_title = #doc_data.examples > 1 and string.format("Example %d", i) or "Example"
      local card_width = math.min(120, window_width - 8)

      -- Example card with copy-friendly border
      table.insert(lines, "    ╭" .. string.rep("─", card_width - 2) .. "╮")

      -- Example header with copy indicator
      local header_line = string.format(
        "    │ %s %s %s Copy-ready",
        ui.icons.copy,
        example_title,
        ui.icons.external_link
      )
      local padding_needed = card_width - #header_line + 3 -- Adjust for leading spaces
      if padding_needed > 0 then
        header_line = header_line .. string.rep(" ", padding_needed)
      end
      header_line = header_line .. "│"
      table.insert(lines, header_line)

      -- Separator
      table.insert(lines, "    ├" .. string.rep("─", card_width - 2) .. "┤")

      -- Clean, unindented example for easy copying
      local example_lines = vim.split(example, "\n")
      local min_indent = nil

      -- Find minimum indentation (excluding empty lines)
      for _, line in ipairs(example_lines) do
        if line:match("%S") then -- Non-empty line
          local indent = line:match("^%s*"):len()
          if not min_indent or indent < min_indent then
            min_indent = indent
          end
        end
      end

      min_indent = min_indent or 0

      -- Add properly formatted code
      for _, line in ipairs(example_lines) do
        local clean_line = line
        if line:match("%S") then -- Non-empty line
          clean_line = line:sub(min_indent + 1) -- Remove common indentation
        end

        local code_line = "    │ " .. clean_line
        local padding_needed = card_width - #code_line + 3
        if padding_needed > 0 then
          code_line = code_line .. string.rep(" ", padding_needed)
        end
        code_line = code_line .. "│"
        table.insert(lines, code_line)
      end

      -- Example footer
      table.insert(lines, "    ╰" .. string.rep("─", card_width - 2) .. "╯")

      -- Generate terraform config template
      if i == 1 then -- Only for first example
        table.insert(lines, "")
        table.insert(lines, "    " .. string.rep("╌", 60))
        table.insert(
          lines,
          string.format("    %s Ready-to-use template (press 't' to copy):", ui.icons.diamond)
        )
        table.insert(lines, "")

        -- Extract resource/data source info from example
        local resource_line = example:match('[^\n]*resource%s+"([^"]+)"%s+"([^"]+)"[^\n]*')
          or example:match('[^\n]*data%s+"([^"]+)"%s+"([^"]+)"[^\n]*')

        if resource_line then
          local resource_type, resource_name = example:match('(%w+)%s+"([^"]+)"%s+"([^"]+)"')
          if resource_type and resource_name then
            -- Generate template arguments from doc_data
            table.insert(
              lines,
              string.format('    %s "%s" "example" {', resource_type, resource_name)
            )

            if doc_data.arguments then
              for _, arg in ipairs(doc_data.arguments) do
                if arg.required == "Required" then
                  local copyable_lines = format_argument_copyable(arg)
                  for _, arg_line in ipairs(copyable_lines) do
                    table.insert(lines, "    " .. arg_line)
                  end
                  table.insert(lines, "")
                end
              end
            end

            table.insert(lines, "    }")
          end
        end
      end

      -- Spacing between examples
      if i < #doc_data.examples then
        table.insert(lines, "")
        table.insert(lines, "")
      end
    end

    table.insert(lines, "")
    table.insert(lines, "")
  end

  -- Enhanced footer with action toolbar
  local footer_line = string.rep("═", window_width)
  table.insert(lines, footer_line)

  local actions = {
    { key = "q", label = "Close" },
    { key = "o", label = "Open URL" },
    { key = "y", label = "Copy Menu" },
    { key = "c", label = "Copy Args" },
    { key = "x", label = "Copy Example" },
    { key = "t", label = "Copy Template" },
    { key = "e", label = "Export" },
    { key = "b", label = "Bookmark" },
    { key = "?", label = "Help" },
  }

  local toolbar_lines = ui.create_action_toolbar(actions)
  for _, line in ipairs(toolbar_lines) do
    table.insert(lines, line)
  end

  table.insert(lines, footer_line)

  return lines
end

--- Show documentation in a floating window
-- @param doc_data table Documentation data
function M.show_documentation(doc_data)
  local lines = create_documentation_content(doc_data)

  -- Calculate window size (much larger for spacious layout)
  local width = math.min(150, vim.o.columns - 4) -- Much wider for better readability
  local height = math.min(#lines + 2, vim.o.lines - 4) -- Use more of the available height

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Terraform Documentation ",
    title_pos = "center",
  })

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "terrareg-docs")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)

  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", true)
  vim.api.nvim_win_set_option(win, "linebreak", true)
  vim.api.nvim_win_set_option(win, "breakindent", true)

  -- Set up key mappings for the documentation window
  local function close_win()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function open_url()
    if doc_data.url then
      vim.fn.system({ "xdg-open", doc_data.url })
      vim.notify("Opened URL in browser: " .. doc_data.url, vim.log.levels.INFO)
    end
  end

  local function export_docs()
    require("terrareg.export").show_export_menu(doc_data)
  end

  local function quick_export()
    require("terrareg.export").quick_export_markdown(doc_data)
  end

  local function show_help()
    ui.show_help("documentation")
  end

  local function copy_arguments()
    if not doc_data.arguments or #doc_data.arguments == 0 then
      ui.notify("No arguments available to copy", "warning")
      return
    end

    local lines = {}
    table.insert(lines, "# Terraform arguments")
    table.insert(lines, "")

    for _, arg in ipairs(doc_data.arguments) do
      local copyable_lines = format_argument_copyable(arg)
      for _, line in ipairs(copyable_lines) do
        table.insert(lines, line)
      end
      table.insert(lines, "")
    end

    local content = table.concat(lines, "\n")
    vim.fn.setreg("+", content)
    ui.notify(string.format("Copied %d arguments to clipboard", #doc_data.arguments), "success")
  end

  local function copy_example()
    if not doc_data.examples or #doc_data.examples == 0 then
      ui.notify("No examples available to copy", "warning")
      return
    end

    -- Use first example by default, could be enhanced to let user choose
    local example = doc_data.examples[1]
    vim.fn.setreg("+", example)
    ui.notify("Example copied to clipboard", "success")
  end

  local function copy_template()
    if not doc_data.arguments then
      ui.notify("No template available to copy", "warning")
      return
    end

    local lines = {}
    local resource_name = doc_data.resource_name or "example_resource"
    local resource_type = doc_data.resource_type or "resource"

    table.insert(lines, string.format('%s "%s" "example" {', resource_type, resource_name))

    -- Add required arguments
    for _, arg in ipairs(doc_data.arguments) do
      if arg.required == "Required" then
        local copyable_lines = format_argument_copyable(arg)
        for _, line in ipairs(copyable_lines) do
          table.insert(lines, line)
        end
        table.insert(lines, "")
      end
    end

    table.insert(lines, "}")

    local content = table.concat(lines, "\n")
    vim.fn.setreg("+", content)
    ui.notify("Template copied to clipboard", "success")
  end

  -- Enhanced key mappings with copy features
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set("n", "q", close_win, opts)
  vim.keymap.set("n", "<Esc>", close_win, opts)
  vim.keymap.set("n", "o", open_url, opts)
  vim.keymap.set("n", "e", export_docs, opts)
  vim.keymap.set("n", "E", quick_export, opts)
  vim.keymap.set("n", "c", copy_arguments, opts)
  vim.keymap.set("n", "x", copy_example, opts)
  vim.keymap.set("n", "t", copy_template, opts)
  vim.keymap.set("n", "?", show_help, opts)

  -- Auto-close on buffer leave
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = close_win,
  })

  -- Enhanced syntax highlighting for modern cards
  vim.cmd([[
    syntax match TerraregDocsHeader "═\+\|🏗️\|📊\|🔗\|ℹ\|◆\|📋"
    syntax match TerraregDocsCardBorder "[╭╮╯╰├┤│─╌]"
    syntax match TerraregDocsRequired "🔴.*REQUIRED"
    syntax match TerraregDocsOptional "🟡.*OPTIONAL"
    syntax match TerraregDocsForceNew "⚠️.*FORCES NEW"
    syntax match TerraregDocsUrl "https\?://[^ ]*"
    syntax match TerraregDocsCopyReady "Copy-ready\|Ready-to-use"
    syntax match TerraregDocsTemplate "Template\|Example"
    syntax match TerraregDocsComment "^\s*#.*"
    syntax match TerraregDocsTip "Tip:.*"
    syntax match TerraregDocsArgName "^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*="

    highlight link TerraregDocsHeader Title
    highlight link TerraregDocsCardBorder Comment
    highlight link TerraregDocsRequired DiffAdd
    highlight link TerraregDocsOptional DiffChange
    highlight link TerraregDocsForceNew WarningMsg
    highlight link TerraregDocsUrl Underlined
    highlight link TerraregDocsCopyReady Special
    highlight link TerraregDocsTemplate Function
    highlight link TerraregDocsComment Comment
    highlight link TerraregDocsTip MoreMsg
    highlight link TerraregDocsArgName Identifier
  ]])
end

--- Show a simple documentation popup
-- @param doc_data table Documentation data
function M.show_documentation_popup(doc_data)
  local content = {}

  if doc_data.description then
    table.insert(content, "📝 " .. doc_data.description)
    table.insert(content, "")
  end

  if doc_data.arguments and #doc_data.arguments > 0 then
    table.insert(content, "⚙️ Key Arguments:")
    for i = 1, math.min(3, #doc_data.arguments) do
      local arg = doc_data.arguments[i]
      table.insert(content, "• " .. arg.name)
    end
    if #doc_data.arguments > 3 then
      table.insert(content, "... and " .. (#doc_data.arguments - 3) .. " more")
    end
  end

  -- Show as a simple notification
  vim.notify(table.concat(content, "\n"), vim.log.levels.INFO, {
    title = doc_data.title or "Terraform Documentation",
    timeout = 5000,
  })
end

--- Insert documentation snippet at cursor
-- @param doc_data table Documentation data
function M.insert_documentation_snippet(doc_data)
  if not doc_data.examples or #doc_data.examples == 0 then
    vim.notify("No examples available for this resource", vim.log.levels.WARN)
    return
  end

  local example = doc_data.examples[1]
  local lines = {}
  for line in example:gmatch("[^\n]+") do
    table.insert(lines, line)
  end

  -- Insert at cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)

  vim.notify("Inserted example code for " .. (doc_data.title or "resource"), vim.log.levels.INFO)
end

return M
