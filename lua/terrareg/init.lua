--- terrareg.nvim - A Neovim plugin for Terraform AWS documentation
-- @module terrareg
-- @author remoterabbit
-- @license GPL-3.0

local M = {}
local ui = require("terrareg.ui")

--- Default configuration for terrareg
-- @table default_config
M.config = {
  -- Display options
  display_mode = "float", -- "float", "popup", or "split"

  -- Window options
  window = {
    width = 150,
    height = 50,
    border = "rounded",
  },

  -- HTTP options
  timeout = 30000, -- 30 seconds

  -- Debug mode
  debug = false,
}

--- Setup function for the plugin
-- Initializes the plugin with user configuration
-- @param opts table|nil User configuration options to override defaults
-- @usage require('terrareg').setup({ debug = true })
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Initialize UI enhancements
  ui.setup()

  -- Initialize statusline integration
  require("terrareg.statusline").setup(M.config.statusline)

  -- Check for telescope dependency (only warn, don't prevent loading)
  local has_telescope = pcall(require, "telescope")
  if not has_telescope then
    ui.notify("telescope.nvim is recommended for full functionality", "warning")
  else
    -- Register telescope extension if available
    pcall(require("telescope").load_extension, "terrareg")
    ui.notify("Telescope extension loaded", "success", { timeout = 1500 })
  end

  if M.config.debug then
    ui.notify("Debug mode enabled", "info")
    require("terrareg.docs").set_debug(true)
  end

  -- Create user commands
  vim.api.nvim_create_user_command("TerraregDebug", function(args)
    local enabled = args.args == "on" or args.args == "true" or args.args == "1"
    require("terrareg.docs").set_debug(enabled)
    ui.notify("Debug mode " .. (enabled and "enabled" or "disabled"), "info")
  end, {
    nargs = 1,
    complete = function()
      return { "on", "off" }
    end,
    desc = "Toggle terrareg debug mode",
  })

  vim.api.nvim_create_user_command("TerraregTest", function(args)
    local resource = args.args or "aws_s3_bucket"
    ui.notify("Testing documentation fetch for " .. resource, "info")
    require("terrareg.docs").fetch_documentation(
      "resource",
      resource,
      nil,
      function(success, data, error)
        if success then
          ui.notify("Successfully fetched documentation for " .. resource, "success")
        else
          ui.notify("Failed to fetch documentation: " .. (error or "unknown error"), "error")
        end
      end
    )
  end, {
    nargs = "?",
    desc = "Test documentation fetching for a resource",
  })

  -- Show welcome message
  ui.notify("terrareg.nvim loaded! Press <leader>th for help", "info", { timeout = 3000 })
end

--- Get current configuration
-- @return table Current plugin configuration
function M.get_config()
  return M.config
end

--- Open AWS resources picker
-- @param opts table|nil Options for the picker
function M.aws_resources(opts)
  require("terrareg.telescope").aws_resources_picker(opts)
end

--- Open AWS resources picker (resources only)
-- @param opts table|nil Options for the picker
function M.aws_resources_only(opts)
  require("terrareg.telescope").resources_picker(opts)
end

--- Open AWS data sources picker
-- @param opts table|nil Options for the picker
function M.aws_data_sources(opts)
  require("terrareg.telescope").data_sources_picker(opts)
end

--- Search for AWS resources
-- @param query string|nil Search query (if nil, will prompt user)
-- @param opts table|nil Options for the picker
function M.search(query, opts)
  if not query then
    query = vim.fn.input("Search AWS resources: ")
    if query == "" then
      return
    end
  end
  require("terrareg.telescope").search_resources(query, opts)
end

--- Show documentation for a specific resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
function M.show_docs(resource_type, resource_name)
  require("terrareg.telescope").show_documentation(resource_type, resource_name)
end

--- Get documentation data for a resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param callback function Callback function (success, doc_data, error)
function M.get_docs(resource_type, resource_name, callback)
  require("terrareg.docs").fetch_documentation(resource_type, resource_name, nil, callback)
end

--- Insert example code for a resource at cursor
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
function M.insert_example(resource_type, resource_name)
  local docs = require("terrareg.docs")
  local display = require("terrareg.display")

  docs.fetch_documentation(resource_type, resource_name, nil, function(success, doc_data, error)
    vim.schedule(function()
      if success then
        display.insert_documentation_snippet(doc_data)
      else
        vim.notify(
          string.format("Failed to fetch documentation: %s", error or "unknown error"),
          vim.log.levels.ERROR
        )
      end
    end)
  end)
end

return M
