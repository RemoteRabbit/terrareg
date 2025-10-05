--- Enhanced Telescope integration with preview for terrareg.nvim
-- @module terrareg.telescope_preview

local M = {}

-- Safely load UI module
local ui
local has_ui, ui_module = pcall(require, "terrareg.ui")
if has_ui then
  ui = ui_module
else
  -- Fallback UI icons if module doesn't load
  ui = {
    icons = {
      loading = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏",
      resource = "🏗️",
      data_source = "📊",
      info = "ℹ",
      diamond = "◆",
      error = "✗",
      warning = "⚠",
      success = "✓",
      required = "🔴",
      optional = "🟡",
      forces_new = "⚠️",
      copy = "📋",
      arrow_down = "▼",
      arrow_right = "▶",
    },
    create_spinner = function(callback)
      return {
        stop = function() end,
        is_active = function()
          return false
        end,
      }
    end,
    notify = function(msg, level, opts)
      vim.notify(msg, vim.log.levels.INFO)
    end,
  }
end

--- Create a previewer for Terraform documentation
-- @param opts table Options for the previewer
-- @return table Telescope previewer
function M.create_documentation_previewer(opts)
  opts = opts or {}

  local previewers = require("telescope.previewers")
  local utils = require("telescope.utils")

  return previewers.new_buffer_previewer({
    title = "Terraform Documentation Preview",
    define_preview = function(self, entry, status)
      local resource = entry.value

      -- Show animated loading message
      local loading_lines = {
        "",
        "  " .. ui.icons.loading:sub(1, 1) .. " Loading documentation...",
        "",
        "  " .. ui.icons.resource .. " Resource: " .. resource.name,
        "  " .. ui.icons.info .. " Type: " .. resource.type,
        "  " .. ui.icons.diamond .. " Category: " .. resource.category,
        "",
      }

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, loading_lines)

      -- Start spinner animation with cleanup tracking and timeout
      local spinner_frame = 1
      local start_time = vim.loop.hrtime()
      local timeout_ns = 30 * 1000 * 1000 * 1000 -- 30 seconds

      local spinner = ui.create_spinner(function(frame)
        -- Check for timeout
        local elapsed = vim.loop.hrtime() - start_time
        if elapsed > timeout_ns then
          if spinner and spinner.stop then
            pcall(spinner.stop)
          end
          return
        end

        if vim.api.nvim_buf_is_valid(self.state.bufnr) then
          local updated_lines = vim.list_extend({}, loading_lines)
          updated_lines[2] = "  " .. frame .. " Loading documentation..."
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(self.state.bufnr) then
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, updated_lines)
            end
          end)
        else
          -- Buffer is invalid, stop spinner
          if spinner and spinner.stop then
            pcall(spinner.stop)
          end
        end
      end)

      -- Fetch documentation asynchronously
      require("terrareg.docs").fetch_documentation(
        resource.type,
        resource.name,
        nil,
        function(success, doc_data, error)
          vim.schedule(function()
            -- Stop spinner safely
            if spinner and spinner.stop and spinner.is_active and spinner.is_active() then
              pcall(spinner.stop)
            end

            if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
              return
            end

            if success then
              local preview_lines = M.create_preview_content(doc_data)
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines)

              -- Set filetype for syntax highlighting
              vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")

              -- Show success notification briefly
              ui.notify("Documentation loaded", "success", { timeout = 1000 })
            else
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
                "",
                "  " .. ui.icons.error .. " Failed to load documentation",
                "",
                "  " .. ui.icons.warning .. " Error: " .. (error or "Unknown error"),
                "  " .. ui.icons.resource .. " Resource: " .. resource.name,
                "",
              })

              -- Show error notification
              ui.notify("Failed to load documentation: " .. (error or "unknown error"), "error")
            end
          end)
        end
      )
    end,
  })
end

--- Create preview content for documentation
-- @param doc_data table Documentation data
-- @return table Lines for preview
function M.create_preview_content(doc_data)
  local lines = {}

  -- Enhanced header for preview with resource type icon
  local resource_icon = ui.icons.resource
  if doc_data.resource_type == "data" then
    resource_icon = ui.icons.data_source
  end

  table.insert(lines, resource_icon .. " " .. (doc_data.title or "Unknown Resource"))
  table.insert(lines, "")

  -- Enhanced description with icon
  if doc_data.description then
    table.insert(lines, ui.icons.info .. " " .. doc_data.description)
    table.insert(lines, "")
  end

  -- Enhanced key arguments (show top 5)
  if doc_data.arguments and #doc_data.arguments > 0 then
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
        "%s Arguments (%d req, %d opt):",
        ui.icons.diamond,
        required_count,
        optional_count
      )
    )
    table.insert(lines, "")

    local args_to_show = math.min(5, #doc_data.arguments)
    for i = 1, args_to_show do
      local arg = doc_data.arguments[i]
      local status_icon = arg.required == "Required" and ui.icons.required or ui.icons.optional
      local default = arg.default and arg.default ~= "" and " (default: " .. arg.default .. ")"
        or ""
      local forces = arg.forces_new and " " .. ui.icons.forces_new or ""

      table.insert(lines, string.format("  %s %s%s%s", status_icon, arg.name, forces, default))

      if arg.description then
        local short_desc = arg.description:sub(1, 60)
        if #arg.description > 60 then
          short_desc = short_desc .. "..."
        end
        table.insert(lines, "      " .. short_desc)
      end
      table.insert(lines, "")
    end

    if #doc_data.arguments > args_to_show then
      table.insert(
        lines,
        string.format(
          "  %s %d more arguments",
          ui.icons.arrow_down,
          #doc_data.arguments - args_to_show
        )
      )
      table.insert(lines, "")
    end
  end

  -- Enhanced example (first one only, compact)
  if doc_data.examples and #doc_data.examples > 0 then
    table.insert(lines, ui.icons.copy .. " Example:")
    table.insert(lines, "")

    local example = doc_data.examples[1]
    local example_lines = vim.split(example, "\n")

    -- Show first 8 lines of example with syntax indication
    table.insert(lines, "  ```terraform")
    for i = 1, math.min(8, #example_lines) do
      table.insert(lines, "  " .. example_lines[i])
    end

    if #example_lines > 8 then
      table.insert(lines, "  " .. ui.icons.arrow_down .. " ...")
    end
    table.insert(lines, "  ```")
  end

  return lines
end

--- Enhanced telescope picker with preview
-- @param resources table List of resources
-- @param opts table Telescope options
function M.create_picker_with_preview(resources, opts)
  opts = opts or {}

  local has_telescope, telescope_pkg = pcall(require, "telescope")
  if not has_telescope then
    error("telescope.nvim is required for terrareg.nvim")
  end

  local telescope = {
    pickers = require("telescope.pickers"),
    finders = require("telescope.finders"),
    conf = require("telescope.config").values,
    actions = require("telescope.actions"),
    action_state = require("telescope.actions.state"),
    previewers = require("telescope.previewers"),
    utils = require("telescope.utils"),
  }

  telescope.pickers
    .new(opts, {
      prompt_title = opts.prompt_title or "AWS Resources with Preview",
      finder = telescope.finders.new_table({
        results = resources,
        entry_maker = function(resource)
          local type_icon = resource.type == "resource" and "🏗️" or "📊"
          local bookmark_icon = require("terrareg.history").is_bookmarked(
            resource.type,
            resource.name
          ) and " ⭐" or ""
          local display_text = string.format(
            "%s %s [%s]%s - %s",
            type_icon,
            resource.name,
            resource.category,
            bookmark_icon,
            resource.description
          )

          return {
            value = resource,
            display = display_text,
            ordinal = resource.name .. " " .. resource.category .. " " .. resource.description,
          }
        end,
      }),
      sorter = telescope.conf.generic_sorter(opts),
      previewer = M.create_documentation_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        telescope.actions.select_default:replace(function()
          local selection = telescope.action_state.get_selected_entry()
          telescope.actions.close(prompt_bufnr)

          if selection then
            local resource = selection.value
            require("terrareg.views").show_documentation_with_mode_selection({
              title = resource.name,
              resource_type = resource.type,
              resource_name = resource.name,
              provider = "aws", -- default provider
            })
          end
        end)

        -- Add copy keybinding
        map("i", "<C-y>", function()
          local selection = telescope.action_state.get_selected_entry()
          if selection then
            local resource = selection.value
            M.copy_from_preview(resource)
          end
        end)

        -- Add bookmark keybinding
        map("i", "<C-b>", function()
          local selection = telescope.action_state.get_selected_entry()
          if selection then
            local resource = selection.value
            M.toggle_bookmark_from_preview(resource)
          end
        end)

        return true
      end,
    })
    :find()
end

--- Copy resource example from preview
-- @param resource table Resource information
function M.copy_from_preview(resource)
  vim.notify("Fetching example to copy...", vim.log.levels.INFO)

  require("terrareg.docs").fetch_documentation(
    resource.type,
    resource.name,
    nil,
    function(success, doc_data, error)
      vim.schedule(function()
        if success then
          require("terrareg.clipboard").copy_example(doc_data)
        else
          vim.notify(
            "Failed to fetch example: " .. (error or "unknown error"),
            vim.log.levels.ERROR
          )
        end
      end)
    end
  )
end

--- Toggle bookmark from preview
-- @param resource table Resource information
function M.toggle_bookmark_from_preview(resource)
  local history = require("terrareg.history")

  if history.is_bookmarked(resource.type, resource.name) then
    history.remove_bookmark(resource.type, resource.name)
  else
    history.add_bookmark(resource.type, resource.name, resource.description)
  end
end

return M
