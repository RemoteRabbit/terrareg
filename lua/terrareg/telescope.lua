--- Telescope integration for terrareg.nvim
-- @module terrareg.telescope

local M = {}
local telescope_preview = require("terrareg.telescope_preview")

-- Lazy load telescope modules
local function get_telescope_modules()
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    error("telescope.nvim is required for terrareg.nvim")
  end

  return {
    pickers = require("telescope.pickers"),
    finders = require("telescope.finders"),
    conf = require("telescope.config").values,
    actions = require("telescope.actions"),
    action_state = require("telescope.actions.state"),
    previewers = require("telescope.previewers"),
    utils = require("telescope.utils"),
  }
end

-- Export for other modules
M.get_telescope_modules = get_telescope_modules

-- Lazy load other modules to avoid circular dependencies
local function get_modules()
  return {
    aws_resources = require("terrareg.aws_resources"),
    docs = require("terrareg.docs"),
    display = require("terrareg.display"),
    cache = require("terrareg.cache"),
    providers = require("terrareg.providers"),
  }
end

-- Cache for preview content to avoid redundant API calls
local preview_cache = {}

--- Create a custom previewer for Terraform documentation
-- @param opts table Options for the previewer
-- @return table Telescope previewer
local function create_terraform_docs_previewer(opts)
  -- Use the enhanced telescope preview module
  return telescope_preview.create_documentation_previewer(opts)
end

-- Legacy preview function for backward compatibility
local function create_terraform_docs_previewer_legacy(opts)
  opts = opts or {}
  local telescope = get_telescope_modules()
  local modules = get_modules()

  return telescope.previewers.new_buffer_previewer({
    title = "Terraform Documentation Preview",
    get_buffer_by_name = function(_, entry)
      return entry.value.name .. "_preview"
    end,
    define_preview = function(self, entry, status)
      local resource = entry.value
      local cache_key = resource.type .. "_" .. resource.name

      -- Check if we have cached preview content
      if preview_cache[cache_key] then
        local lines = preview_cache[cache_key]
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "terraform-docs")
        return
      end

      -- Show loading message
      local loading_lines = {
        "📖 Loading documentation...",
        "",
        "Resource: " .. resource.name,
        "Type: " .. resource.type,
        "Category: " .. (resource.category or "Unknown"),
        "",
        "⏳ Fetching from provider...",
      }
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, loading_lines)

      -- Fetch documentation asynchronously
      modules.docs.fetch_documentation(
        resource.type,
        resource.name,
        nil,
        function(success, doc_data, error)
          vim.schedule(function()
            -- Double-check buffer is still valid
            if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
              return
            end

            local preview_lines = {}

            if success and doc_data then
              -- Create compact preview content
              table.insert(preview_lines, "📖 " .. (doc_data.title or resource.name))
              table.insert(preview_lines, "")

              if doc_data.description then
                table.insert(preview_lines, "📝 Description:")
                local wrapped_desc = M.wrap_text_for_preview(doc_data.description, 80)
                for line in wrapped_desc:gmatch("[^\n]+") do
                  table.insert(preview_lines, "  " .. line)
                end
                table.insert(preview_lines, "")
              end

              -- Show key arguments
              if doc_data.arguments and #doc_data.arguments > 0 then
                table.insert(preview_lines, "⚙️ Key Arguments:")
                local required_count = 0
                local optional_count = 0

                for i, arg in ipairs(doc_data.arguments) do
                  if i <= 5 then -- Show first 5 arguments
                    local status = arg.required == "Required" and "🔴 Required" or "⚪ Optional"
                    table.insert(preview_lines, string.format("  • %s - %s", arg.name, status))
                    if arg.description and #arg.description < 60 then
                      table.insert(preview_lines, "    " .. arg.description)
                    end
                  end

                  if arg.required == "Required" then
                    required_count = required_count + 1
                  else
                    optional_count = optional_count + 1
                  end
                end

                if #doc_data.arguments > 5 then
                  table.insert(
                    preview_lines,
                    "  ... and " .. (#doc_data.arguments - 5) .. " more arguments"
                  )
                end

                table.insert(preview_lines, "")
                table.insert(
                  preview_lines,
                  string.format(
                    "📊 Total: %d required, %d optional",
                    required_count,
                    optional_count
                  )
                )
              end

              -- Show example if available
              if doc_data.example then
                table.insert(preview_lines, "")
                table.insert(preview_lines, "💡 Example:")
                local example_lines = vim.split(doc_data.example, "\n")
                for i, line in ipairs(example_lines) do
                  if i <= 10 then -- Show first 10 lines of example
                    table.insert(preview_lines, "  " .. line)
                  end
                end
                if #example_lines > 10 then
                  table.insert(preview_lines, "  ...")
                end
              end

              table.insert(preview_lines, "")
              table.insert(preview_lines, "Press <Enter> to view full documentation")
            else
              table.insert(preview_lines, "❌ Failed to load documentation")
              table.insert(preview_lines, "")
              table.insert(preview_lines, "Error: " .. (error or "Unknown error"))
              table.insert(preview_lines, "")
              table.insert(preview_lines, "Resource: " .. resource.name)
              table.insert(preview_lines, "Type: " .. resource.type)
            end

            -- Cache the preview content
            preview_cache[cache_key] = preview_lines

            -- Set content in buffer
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines)
            vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "terraform-docs")
          end)
        end
      )
    end,
  })
end

--- Wrap text for preview display
-- @param text string Text to wrap
-- @param width number Maximum width
-- @return string Wrapped text
function M.wrap_text_for_preview(text, width)
  if not text or text == "" then
    return ""
  end

  width = width or 80
  local result = {}
  local current_line = ""

  for word in text:gmatch("%S+") do
    if #current_line + #word + 1 <= width then
      current_line = current_line == "" and word or current_line .. " " .. word
    else
      if current_line ~= "" then
        table.insert(result, current_line)
      end
      current_line = word
    end
  end

  if current_line ~= "" then
    table.insert(result, current_line)
  end

  return table.concat(result, "\n")
end

--- Create a Telescope picker for AWS resources
-- @param opts table|nil Options for the picker
function M.aws_resources_picker(opts)
  opts = opts or {}

  local telescope = get_telescope_modules()
  local modules = get_modules()

  local resources = modules.aws_resources.get_all_resources()

  telescope.pickers
    .new(opts, {
      prompt_title = "AWS Resources & Data Sources",
      finder = telescope.finders.new_table({
        results = resources,
        entry_maker = function(resource)
          local type_icon = resource.type == "resource" and "🏗️" or "📊"
          local display_text = string.format(
            "%s %s [%s] - %s",
            type_icon,
            resource.name,
            resource.category,
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
      previewer = create_terraform_docs_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        telescope.actions.select_default:replace(function()
          local selection = telescope.action_state.get_selected_entry()
          telescope.actions.close(prompt_bufnr)

          if selection then
            local resource = selection.value
            M.show_documentation(resource.type, resource.name)
          end
        end)

        -- Add custom mapping for cache clearing
        map("i", "<C-r>", function()
          preview_cache = {}
          vim.notify("Preview cache cleared", vim.log.levels.INFO)
        end)

        -- Copy resource name to clipboard
        map("i", "<C-y>", function()
          local selection = telescope.action_state.get_selected_entry()
          if selection then
            local resource = selection.value
            vim.fn.setreg("+", resource.name)
            vim.notify("Copied " .. resource.name .. " to clipboard", vim.log.levels.INFO)
          end
        end)

        return true
      end,
    })
    :find()
end

--- Show documentation for a specific resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
function M.show_documentation(resource_type, resource_name)
  vim.notify(
    string.format("Fetching documentation for %s %s...", resource_type, resource_name),
    vim.log.levels.INFO
  )

  local modules = get_modules()

  modules.docs.fetch_documentation(
    resource_type,
    resource_name,
    nil,
    function(success, doc_data, error)
      vim.schedule(function()
        if success then
          modules.display.show_documentation(doc_data)
        else
          vim.notify(
            string.format("Failed to fetch documentation: %s", error or "unknown error"),
            vim.log.levels.ERROR
          )
        end
      end)
    end
  )
end

--- Create filtered picker for resources only
-- @param opts table|nil Options for the picker
function M.resources_picker(opts)
  opts = opts or {}

  local telescope = get_telescope_modules()
  local modules = get_modules()

  local resources = modules.aws_resources.get_resources_by_type("resource")

  telescope.pickers
    .new(opts, {
      prompt_title = "AWS Resources",
      finder = telescope.finders.new_table({
        results = resources,
        entry_maker = function(resource)
          local display_text = string.format(
            "🏗️ %s [%s] - %s",
            resource.name,
            resource.category,
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
      previewer = create_terraform_docs_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        telescope.actions.select_default:replace(function()
          local selection = telescope.action_state.get_selected_entry()
          telescope.actions.close(prompt_bufnr)

          if selection then
            local resource = selection.value
            M.show_documentation(resource.type, resource.name)
          end
        end)

        return true
      end,
    })
    :find()
end

--- Create filtered picker for data sources only
-- @param opts table|nil Options for the picker
function M.data_sources_picker(opts)
  opts = opts or {}

  local telescope = get_telescope_modules()
  local modules = get_modules()

  local data_sources = modules.aws_resources.get_resources_by_type("data")

  telescope.pickers
    .new(opts, {
      prompt_title = "AWS Data Sources",
      finder = telescope.finders.new_table({
        results = data_sources,
        entry_maker = function(resource)
          local display_text = string.format(
            "📊 %s [%s] - %s",
            resource.name,
            resource.category,
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
      previewer = create_terraform_docs_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        telescope.actions.select_default:replace(function()
          local selection = telescope.action_state.get_selected_entry()
          telescope.actions.close(prompt_bufnr)

          if selection then
            local resource = selection.value
            M.show_documentation(resource.type, resource.name)
          end
        end)

        return true
      end,
    })
    :find()
end

--- Search for resources based on query
-- @param query string Search query
-- @param opts table|nil Options for the picker
function M.search_resources(query, opts)
  opts = opts or {}

  local telescope = get_telescope_modules()
  local modules = get_modules()

  local results = modules.aws_resources.search_resources(query)

  if #results == 0 then
    vim.notify("No resources found matching: " .. query, vim.log.levels.WARN)
    return
  end

  telescope.pickers
    .new(opts, {
      prompt_title = "Search Results: " .. query,
      finder = telescope.finders.new_table({
        results = results,
        entry_maker = function(resource)
          local type_icon = resource.type == "resource" and "🏗️" or "📊"
          local display_text = string.format(
            "%s %s [%s] - %s",
            type_icon,
            resource.name,
            resource.category,
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
      previewer = create_terraform_docs_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        telescope.actions.select_default:replace(function()
          local selection = telescope.action_state.get_selected_entry()
          telescope.actions.close(prompt_bufnr)

          if selection then
            local resource = selection.value
            M.show_documentation(resource.type, resource.name)
          end
        end)

        return true
      end,
    })
    :find()
end

return M
