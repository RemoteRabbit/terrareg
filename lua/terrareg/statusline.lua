--- Enhanced status line integration for terrareg.nvim
-- @module terrareg.statusline

local M = {}
local ui = require("terrareg.ui")

--- Current terrareg status
M.status = {
  provider = nil,
  resource_count = 0,
  bookmark_count = 0,
  last_search = nil,
  active_documentation = nil,
}

--- Update provider status
-- @param provider string Provider name
-- @param resource_count number Number of resources
function M.set_provider_status(provider, resource_count)
  M.status.provider = provider
  M.status.resource_count = resource_count or 0
  M._notify_statusline_update()
end

--- Update bookmark count
-- @param count number Number of bookmarks
function M.set_bookmark_count(count)
  M.status.bookmark_count = count or 0
  M._notify_statusline_update()
end

--- Set last search query
-- @param query string Search query
function M.set_last_search(query)
  M.status.last_search = query
  M._notify_statusline_update()
end

--- Set active documentation
-- @param doc_info table Documentation info
function M.set_active_documentation(doc_info)
  M.status.active_documentation = doc_info
  M._notify_statusline_update()
end

--- Clear all status
function M.clear()
  M.status = {
    provider = nil,
    resource_count = 0,
    bookmark_count = 0,
    last_search = nil,
    active_documentation = nil,
  }
  M._notify_statusline_update()
end

--- Get terrareg statusline component
-- @return string Formatted statusline segment
function M.get_statusline()
  local segments = {}

  -- Active documentation indicator
  if M.status.active_documentation then
    local doc_icon = ui.icons.resource
    if M.status.active_documentation.type == "data" then
      doc_icon = ui.icons.data_source
    end
    table.insert(segments, doc_icon .. " " .. M.status.active_documentation.name)
  end

  -- Provider status
  if M.status.provider then
    table.insert(segments, ui.icons.provider .. " " .. M.status.provider)

    if M.status.resource_count > 0 then
      table.insert(segments, string.format("(%d resources)", M.status.resource_count))
    end
  end

  -- Bookmark count
  if M.status.bookmark_count > 0 then
    table.insert(segments, ui.icons.bookmark .. " " .. M.status.bookmark_count)
  end

  -- Last search
  if M.status.last_search and M.status.last_search ~= "" then
    local search_display = M.status.last_search
    if #search_display > 20 then
      search_display = search_display:sub(1, 17) .. "..."
    end
    table.insert(segments, ui.icons.search .. " " .. search_display)
  end

  if #segments == 0 then
    return ""
  end

  return "terrareg: " .. table.concat(segments, " | ")
end

--- Get compact statusline for minimal displays
-- @return string Compact statusline
function M.get_compact_statusline()
  local segments = {}

  if M.status.active_documentation then
    local icon = M.status.active_documentation.type == "data" and ui.icons.data_source
      or ui.icons.resource
    table.insert(segments, icon)
  end

  if M.status.provider then
    table.insert(segments, ui.icons.provider)
  end

  if M.status.bookmark_count > 0 then
    table.insert(segments, ui.icons.bookmark .. M.status.bookmark_count)
  end

  if #segments == 0 then
    return ""
  end

  return table.concat(segments, " ")
end

--- Get detailed status for debugging
-- @return table Complete status information
function M.get_debug_status()
  return vim.deepcopy(M.status)
end

--- Notify statusline plugins of updates
function M._notify_statusline_update()
  -- Trigger statusline refresh for common statusline plugins
  if vim.g.loaded_lualine then
    -- Lualine refresh
    vim.schedule(function()
      pcall(require, "lualine").refresh()
    end)
  elseif vim.g.loaded_lightline then
    -- Lightline refresh
    vim.cmd("call lightline#update()")
  elseif vim.g.airline_theme then
    -- Airline refresh
    vim.cmd("AirlineRefresh")
  end

  -- Trigger redraw for default statusline
  vim.cmd("redrawstatus")
end

--- Integration with lualine
-- @return table Lualine component configuration
function M.lualine_component()
  return {
    function()
      return M.get_statusline()
    end,
    icon = ui.icons.provider,
    color = { fg = "#0066cc" },
    cond = function()
      return M.status.provider ~= nil or M.status.active_documentation ~= nil
    end,
  }
end

--- Integration with airline
function M.setup_airline()
  vim.cmd([[
    function! TerraregStatusline()
      return v:lua.require('terrareg.statusline').get_statusline()
    endfunction

    let g:airline_section_x = get(g:, 'airline_section_x', '') . '%{TerraregStatusline()}'
  ]])
end

--- Setup statusline integration
-- @param opts table Options for statusline setup
function M.setup(opts)
  opts = opts or {}

  -- Auto-detect and integrate with statusline plugins
  if opts.auto_integrate ~= false then
    vim.schedule(function()
      if vim.g.loaded_lualine then
        -- User can manually add the component to their lualine config
        ui.notify(
          "Lualine detected - add require('terrareg.statusline').lualine_component() to your config",
          "info"
        )
      elseif vim.g.airline_theme then
        M.setup_airline()
        ui.notify("Airline statusline integration enabled", "success")
      end
    end)
  end

  -- Set up global statusline function for manual integration
  _G.terrareg_statusline = M.get_statusline
  _G.terrareg_statusline_compact = M.get_compact_statusline
end

return M
