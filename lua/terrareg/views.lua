--- View management for terrareg.nvim (float, split, etc.)
-- @module terrareg.views

local M = {}

--- Show documentation in vertical split
-- @param doc_data table Documentation data
-- @param opts table|nil Options
function M.show_documentation_vsplit(doc_data, opts)
  opts = opts or {}
  local width = opts.width or 80

  -- Create vertical split
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_width(win, width)

  M._setup_documentation_buffer(buf, win, doc_data, "vsplit")
end

--- Show documentation in horizontal split
-- @param doc_data table Documentation data
-- @param opts table|nil Options
function M.show_documentation_hsplit(doc_data, opts)
  opts = opts or {}
  local height = opts.height or 20

  -- Create horizontal split
  vim.cmd("split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, height)

  M._setup_documentation_buffer(buf, win, doc_data, "hsplit")
end

--- Show documentation in new tab
-- @param doc_data table Documentation data
function M.show_documentation_tab(doc_data)
  vim.cmd("tabnew")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  M._setup_documentation_buffer(buf, win, doc_data, "tab")
end

--- Setup documentation buffer
-- @param buf number Buffer number
-- @param win number Window number
-- @param doc_data table Documentation data
-- @param view_type string Type of view ("float", "vsplit", "hsplit", "tab")
function M._setup_documentation_buffer(buf, win, doc_data, view_type)
  local display = require("terrareg.display")
  local lines = display.create_documentation_content
      and display.create_documentation_content(doc_data)
    or { "Documentation loading..." }

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", view_type == "tab" and "delete" or "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "terraform-docs")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)
  vim.api.nvim_buf_set_option(buf, "swapfile", false)

  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", true)
  vim.api.nvim_win_set_option(win, "linebreak", true)
  vim.api.nvim_win_set_option(win, "breakindent", true)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)

  -- Setup enhanced features
  require("terrareg.syntax").setup_documentation_syntax(buf)
  require("terrareg.syntax").setup_folding(buf)
  require("terrareg.search").setup_keymaps(buf, win)

  -- View-specific key mappings
  M._setup_view_keymaps(buf, win, doc_data, view_type)
end

--- Setup key mappings for different view types
-- @param buf number Buffer number
-- @param win number Window number
-- @param doc_data table Documentation data
-- @param view_type string View type
function M._setup_view_keymaps(buf, win, doc_data, view_type)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Common mappings
  local function copy_menu()
    require("terrareg.clipboard").show_copy_menu(doc_data)
  end

  local function export_menu()
    require("terrareg.export").export_current(doc_data)
  end

  local function toggle_bookmark()
    local history = require("terrareg.history")
    local resource_info = M._parse_resource_from_title(doc_data.title)

    if resource_info then
      if history.is_bookmarked(resource_info.type, resource_info.name) then
        history.remove_bookmark(resource_info.type, resource_info.name)
      else
        history.add_bookmark(resource_info.type, resource_info.name, doc_data.description)
      end
    end
  end

  local function toggle_theme()
    local themes = { "default", "dark", "light" }
    local current = vim.g.terrareg_theme or "default"
    local current_index = 1

    for i, theme in ipairs(themes) do
      if theme == current then
        current_index = i
        break
      end
    end

    local next_index = (current_index % #themes) + 1
    local next_theme = themes[next_index]

    vim.g.terrareg_theme = next_theme
    require("terrareg.syntax").apply_theme(buf, next_theme)
  end

  -- View-specific close behavior
  local function close_view()
    require("terrareg.search").clear_search()

    if view_type == "float" then
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    elseif view_type == "vsplit" or view_type == "hsplit" then
      vim.cmd("close")
    elseif view_type == "tab" then
      vim.cmd("tabclose")
    end
  end

  -- Key mappings
  vim.keymap.set("n", "q", close_view, opts)
  vim.keymap.set("n", "<Esc>", close_view, opts)
  vim.keymap.set("n", "y", copy_menu, opts)
  vim.keymap.set("n", "e", export_menu, opts)
  vim.keymap.set("n", "b", toggle_bookmark, opts)
  vim.keymap.set("n", "t", toggle_theme, opts)

  -- Open URL
  vim.keymap.set("n", "o", function()
    if doc_data.url then
      vim.fn.system({ "xdg-open", doc_data.url })
      vim.notify("Opened URL in browser: " .. doc_data.url, vim.log.levels.INFO)
    end
  end, opts)

  -- Toggle folding
  vim.keymap.set("n", "z", function()
    if vim.wo.foldenable then
      vim.cmd("set nofoldenable")
      vim.notify("Folding disabled", vim.log.levels.INFO)
    else
      vim.cmd("set foldenable")
      vim.notify("Folding enabled", vim.log.levels.INFO)
    end
  end, opts)

  -- Syntax toggle
  vim.keymap.set("n", "s", function()
    require("terrareg.syntax").toggle_syntax(buf)
  end, opts)
end

--- Parse resource information from title
-- @param title string Documentation title
-- @return table|nil Resource information
function M._parse_resource_from_title(title)
  if not title then
    return nil
  end

  -- Try to extract resource type and name from title
  local resource_name = title:match("aws_[%w_]+")
    or title:match("azurerm_[%w_]+")
    or title:match("google_[%w_]+")
  if resource_name then
    return {
      type = "resource", -- Default assumption
      name = resource_name,
    }
  end

  return nil
end

--- Show documentation with view mode selection
-- @param doc_data table Documentation data
function M.show_documentation_with_mode_selection(doc_data)
  local config = require("terrareg").get_config()
  local mode = config.display_mode or "float"

  if mode == "float" then
    require("terrareg.display").show_documentation(doc_data)
  elseif mode == "vsplit" then
    M.show_documentation_vsplit(doc_data, config.window)
  elseif mode == "hsplit" then
    M.show_documentation_hsplit(doc_data, config.window)
  elseif mode == "tab" then
    M.show_documentation_tab(doc_data)
  else
    -- Default to float
    require("terrareg.display").show_documentation(doc_data)
  end
end

--- Change view mode for current session
-- @param mode string "float", "vsplit", "hsplit", or "tab"
function M.set_view_mode(mode)
  local valid_modes = { "float", "vsplit", "hsplit", "tab" }
  local is_valid = false

  for _, valid_mode in ipairs(valid_modes) do
    if mode == valid_mode then
      is_valid = true
      break
    end
  end

  if not is_valid then
    vim.notify(
      "Invalid view mode: " .. mode .. ". Valid modes: " .. table.concat(valid_modes, ", "),
      vim.log.levels.ERROR
    )
    return
  end

  local terrareg = require("terrareg")
  terrareg.config.display_mode = mode
  vim.notify("View mode set to: " .. mode, vim.log.levels.INFO)
end

return M
