--- Enhanced UI components and utilities for terrareg.nvim
-- @module terrareg.ui

local M = {}

--- UI Icons and symbols
M.icons = {
  -- Status indicators
  loading = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏", -- Spinner frames
  success = "✓",
  error = "✗",
  warning = "⚠",
  info = "ℹ",

  -- Resource types
  resource = "🏗️",
  data_source = "📊",
  module = "📦",
  provider = "🔌",

  -- Actions
  bookmark = "⭐",
  copy = "📋",
  export = "💾",
  search = "🔍",
  external_link = "🔗",

  -- UI Elements
  arrow_right = "▶",
  arrow_down = "▼",
  bullet = "•",
  diamond = "◆",

  -- Terraform specific
  required = "🔴",
  optional = "🟡",
  forces_new = "⚠️",
  deprecated = "⚠️",
}

--- Color schemes for enhanced theming
M.colors = {
  default = {
    primary = "#0066cc",
    secondary = "#6c757d",
    success = "#28a745",
    warning = "#ffc107",
    error = "#dc3545",
    info = "#17a2b8",
    border = "#dee2e6",
    background = "#ffffff",
    text = "#212529",
  },

  dark = {
    primary = "#0d7377",
    secondary = "#495057",
    success = "#20c997",
    warning = "#fd7e14",
    error = "#e74c3c",
    info = "#6f42c1",
    border = "#343a40",
    background = "#212529",
    text = "#f8f9fa",
  },

  nord = {
    primary = "#5e81ac",
    secondary = "#4c566a",
    success = "#a3be8c",
    warning = "#ebcb8b",
    error = "#bf616a",
    info = "#88c0d0",
    border = "#3b4252",
    background = "#2e3440",
    text = "#eceff4",
  },
}

--- Create an animated loading spinner
-- @param callback function Function to call when animation should stop
-- @return table Animation controller
function M.create_spinner(callback)
  local frames = M.icons.loading
  local current_frame = 1
  local timer = nil
  local active = true
  local stopped = false

  local function update_spinner()
    if not active or stopped then
      return
    end

    local frame = frames:sub(current_frame, current_frame)
    if callback then
      pcall(callback, frame) -- Safely call callback
    end

    current_frame = current_frame + 1
    if current_frame > #frames then
      current_frame = 1
    end
  end

  -- Start animation with error handling
  local success = pcall(function()
    timer = vim.loop.new_timer()
    if timer then
      timer:start(0, 100, vim.schedule_wrap(update_spinner))
    end
  end)

  if not success then
    -- Fallback if timer creation fails
    timer = nil
  end

  return {
    stop = function()
      if stopped then
        return -- Already stopped
      end

      stopped = true
      active = false

      if timer and not timer:is_closing() then
        pcall(function()
          timer:stop()
          timer:close()
        end)
        timer = nil
      end
    end,

    is_active = function()
      return active and not stopped
    end,
  }
end

--- Create a progress bar
-- @param current number Current progress (0-100)
-- @param total number Total progress (0-100)
-- @param width number Width of progress bar
-- @return string Progress bar string
function M.create_progress_bar(current, total, width)
  width = width or 20
  local percentage = math.floor((current / total) * 100)
  local filled = math.floor((current / total) * width)
  local empty = width - filled

  local bar = string.rep("█", filled) .. string.rep("░", empty)
  return string.format("[%s] %d%%", bar, percentage)
end

--- Create a notification with enhanced styling
-- @param message string Notification message
-- @param level string Log level ("info", "warn", "error", "success")
-- @param opts table Additional options
function M.notify(message, level, opts)
  opts = opts or {}
  level = level or "info"

  local icon = M.icons[level] or M.icons.info
  local title = opts.title or "Terrareg"

  -- Enhanced notification with icon
  local formatted_message = string.format("%s %s", icon, message)

  local log_level = vim.log.levels.INFO
  if level == "warn" then
    log_level = vim.log.levels.WARN
  elseif level == "error" then
    log_level = vim.log.levels.ERROR
  end

  vim.notify(formatted_message, log_level, {
    title = title,
    timeout = opts.timeout or 3000,
    icon = icon,
  })
end

--- Create a floating window with enhanced styling
-- @param content table Lines of content
-- @param opts table Window options
-- @return number, number Buffer and window handles
function M.create_enhanced_float(content, opts)
  opts = opts or {}

  local width = opts.width or math.min(120, vim.o.columns - 10)
  local height = opts.height or math.min(40, vim.o.lines - 10)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

  -- Enhanced window options
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = opts.title and (" " .. opts.title .. " ") or nil,
    title_pos = "center",
  }

  -- Add footer if provided
  if opts.footer then
    win_opts.footer = " " .. opts.footer .. " "
    win_opts.footer_pos = "center"
  end

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)

  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", opts.wrap ~= false)
  vim.api.nvim_win_set_option(win, "linebreak", true)
  vim.api.nvim_win_set_option(win, "breakindent", true)

  return buf, win
end

--- Create a help panel with key mappings
-- @param mappings table Key mapping definitions
-- @return table Content lines for help panel
function M.create_help_panel(mappings)
  local lines = {}

  table.insert(lines, "")
  table.insert(lines, "📖 KEYBOARD SHORTCUTS")
  table.insert(lines, string.rep("─", 50))
  table.insert(lines, "")

  for _, mapping in ipairs(mappings) do
    local key_display = string.format("%-12s", mapping.key)
    local desc_display = mapping.description
    table.insert(lines, string.format("  %s %s %s", key_display, M.icons.arrow_right, desc_display))
  end

  table.insert(lines, "")
  table.insert(lines, string.rep("─", 50))
  table.insert(lines, "Press any key to close this help")

  return lines
end

--- Show contextual help for current buffer
-- @param context string Context name (e.g., "documentation", "search")
function M.show_help(context)
  local mappings = {} -- luacheck: ignore 311

  if context == "documentation" then
    mappings = {
      { key = "q / <Esc>", description = "Close documentation" },
      { key = "o", description = "Open URL in browser" },
      { key = "y", description = "Copy menu" },
      { key = "c", description = "Copy all arguments with comments" },
      { key = "x", description = "Copy example code" },
      { key = "t", description = "Copy ready-to-use template" },
      { key = "e", description = "Export menu" },
      { key = "E", description = "Quick export to markdown" },
      { key = "b", description = "Toggle bookmark" },
      { key = "/", description = "Search within document" },
      { key = "n / N", description = "Next/previous search result" },
      { key = "?", description = "Show this help" },
    }
  elseif context == "telescope" then
    mappings = {
      { key = "<C-n/p>", description = "Navigate up/down" },
      { key = "<CR>", description = "Select resource" },
      { key = "<C-v>", description = "Open in vertical split" },
      { key = "<C-x>", description = "Open in horizontal split" },
      { key = "<C-t>", description = "Open in new tab" },
      { key = "<C-y>", description = "Copy example from preview" },
      { key = "<C-b>", description = "Toggle bookmark" },
      { key = "<Esc>", description = "Close picker" },
    }
  else
    mappings = {
      { key = "?", description = "Show help for current context" },
    }
  end

  local content = M.create_help_panel(mappings)
  local buf, win = M.create_enhanced_float(content, {
    title = "Help: " .. (context or "General"),
    footer = "terrareg.nvim",
    width = 60,
    height = #content + 2,
  })

  -- Close on any key press
  vim.keymap.set("n", "<buffer>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf })
end

--- Create a breadcrumb navigation display
-- @param path table Navigation path segments
-- @return string Formatted breadcrumb
function M.create_breadcrumb(path)
  if not path or #path == 0 then
    return ""
  end

  local segments = {}
  for i, segment in ipairs(path) do
    table.insert(segments, segment)
    if i < #path then
      table.insert(segments, M.icons.arrow_right)
    end
  end

  return table.concat(segments, " ")
end

--- Create a status line segment for terrareg
-- @param status table Status information
-- @return string Status line content
function M.create_status_segment(status)
  if not status then
    return ""
  end

  local segments = {}

  -- Provider indicator
  if status.provider then
    table.insert(segments, M.icons.provider .. " " .. status.provider)
  end

  -- Resource count
  if status.resource_count then
    table.insert(segments, string.format("%s %d", M.icons.resource, status.resource_count))
  end

  -- Active bookmarks
  if status.bookmark_count and status.bookmark_count > 0 then
    table.insert(segments, string.format("%s %d", M.icons.bookmark, status.bookmark_count))
  end

  return table.concat(segments, " | ")
end

--- Create a quick action toolbar
-- @param actions table Action definitions
-- @return table Toolbar content lines
function M.create_action_toolbar(actions)
  local lines = {}
  local toolbar_line = {}

  for _, action in ipairs(actions) do
    local button = string.format("[%s] %s", action.key, action.label)
    table.insert(toolbar_line, button)
  end

  table.insert(lines, table.concat(toolbar_line, "  "))
  table.insert(lines, string.rep("─", #table.concat(toolbar_line, "  ")))

  return lines
end

--- Show a confirmation dialog
-- @param message string Confirmation message
-- @param callback function Callback with result (true/false)
-- @param opts table Dialog options
function M.confirm(message, callback, opts)
  opts = opts or {} -- luacheck: ignore 311

  vim.ui.select({ "Yes", "No" }, {
    prompt = message,
    format_item = function(item)
      local icon = item == "Yes" and M.icons.success or M.icons.error
      return string.format("%s %s", icon, item)
    end,
  }, function(choice)
    if callback then
      callback(choice == "Yes")
    end
  end)
end

--- Create an enhanced input dialog
-- @param prompt string Input prompt
-- @param callback function Callback with input result
-- @param opts table Input options
function M.input(prompt, callback, opts)
  opts = opts or {}

  local enhanced_prompt = string.format("%s %s", M.icons.info, prompt)

  vim.ui.input({
    prompt = enhanced_prompt,
    default = opts.default,
    completion = opts.completion,
  }, callback)
end

--- Initialize UI enhancements
function M.setup()
  -- Set up global UI theme
  vim.g.terrareg_ui_theme = vim.g.terrareg_ui_theme or "default"

  -- Enhanced notification function
  _G.terrareg_notify = M.notify

  -- Global help shortcut
  vim.keymap.set("n", "<leader>th", function()
    M.show_help("general")
  end, { desc = "Show Terrareg help" })
end

return M
