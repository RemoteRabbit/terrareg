--- History and recent searches for terrareg.nvim
-- @module terrareg.history

local M = {}

-- History configuration
M.config = {
  max_history = 50,
  history_file = vim.fn.stdpath("data") .. "/terrareg_history.json",
}

-- In-memory history
M.history = {
  recent = {},
  searches = {},
  bookmarks = {},
}

--- Initialize history system
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  M.load_history()
end

--- Load history from file
function M.load_history()
  if vim.fn.filereadable(M.config.history_file) == 0 then
    return
  end

  local ok, content = pcall(vim.fn.readfile, M.config.history_file)
  if not ok or not content or #content == 0 then
    return
  end

  local json_str = table.concat(content, "\n")
  local ok_decode, history_data = pcall(vim.fn.json_decode, json_str)

  if ok_decode and history_data then
    M.history = vim.tbl_deep_extend("force", M.history, history_data)
  end
end

--- Save history to file
function M.save_history()
  vim.schedule(function()
    local json_str = vim.fn.json_encode(M.history)
    pcall(vim.fn.writefile, { json_str }, M.config.history_file)
  end)
end

--- Add resource to recent history
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param doc_data table Documentation data (optional)
function M.add_recent(resource_type, resource_name, doc_data)
  local entry = {
    resource_type = resource_type,
    resource_name = resource_name,
    timestamp = os.time(),
    title = doc_data and doc_data.title or resource_name,
    description = doc_data and doc_data.description or "",
  }

  -- Remove existing entry if present
  M.history.recent = vim.tbl_filter(function(item)
    return not (item.resource_type == resource_type and item.resource_name == resource_name)
  end, M.history.recent)

  -- Add to beginning
  table.insert(M.history.recent, 1, entry)

  -- Limit history size
  if #M.history.recent > M.config.max_history then
    M.history.recent = vim.list_slice(M.history.recent, 1, M.config.max_history)
  end

  M.save_history()
end

--- Add search query to search history
-- @param query string Search query
function M.add_search(query)
  if not query or query == "" then
    return
  end

  -- Remove existing entry if present
  M.history.searches = vim.tbl_filter(function(item)
    return item ~= query
  end, M.history.searches)

  -- Add to beginning
  table.insert(M.history.searches, 1, query)

  -- Limit search history size
  if #M.history.searches > M.config.max_history then
    M.history.searches = vim.list_slice(M.history.searches, 1, M.config.max_history)
  end

  M.save_history()
end

--- Get recent resources
-- @param limit number|nil Maximum number of entries to return
-- @return table List of recent resources
function M.get_recent(limit)
  limit = limit or 10
  return vim.list_slice(M.history.recent, 1, math.min(limit, #M.history.recent))
end

--- Get search history
-- @param limit number|nil Maximum number of entries to return
-- @return table List of recent searches
function M.get_searches(limit)
  limit = limit or 10
  return vim.list_slice(M.history.searches, 1, math.min(limit, #M.history.searches))
end

--- Add bookmark
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param note string|nil Optional note
function M.add_bookmark(resource_type, resource_name, note)
  local bookmark = {
    resource_type = resource_type,
    resource_name = resource_name,
    note = note or "",
    timestamp = os.time(),
  }

  -- Remove existing bookmark if present
  M.history.bookmarks = vim.tbl_filter(function(item)
    return not (item.resource_type == resource_type and item.resource_name == resource_name)
  end, M.history.bookmarks)

  -- Add bookmark
  table.insert(M.history.bookmarks, bookmark)

  M.save_history()
  vim.notify(string.format("Bookmarked %s %s", resource_type, resource_name), vim.log.levels.INFO)
end

--- Remove bookmark
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
function M.remove_bookmark(resource_type, resource_name)
  local initial_count = #M.history.bookmarks

  M.history.bookmarks = vim.tbl_filter(function(item)
    return not (item.resource_type == resource_type and item.resource_name == resource_name)
  end, M.history.bookmarks)

  if #M.history.bookmarks < initial_count then
    M.save_history()
    vim.notify(
      string.format("Removed bookmark for %s %s", resource_type, resource_name),
      vim.log.levels.INFO
    )
  else
    vim.notify(
      string.format("No bookmark found for %s %s", resource_type, resource_name),
      vim.log.levels.WARN
    )
  end
end

--- Check if resource is bookmarked
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @return boolean True if bookmarked
function M.is_bookmarked(resource_type, resource_name)
  for _, bookmark in ipairs(M.history.bookmarks) do
    if bookmark.resource_type == resource_type and bookmark.resource_name == resource_name then
      return true
    end
  end
  return false
end

--- Get all bookmarks
-- @return table List of bookmarks
function M.get_bookmarks()
  return M.history.bookmarks
end

--- Clear all history
function M.clear_all()
  M.history = {
    recent = {},
    searches = {},
    bookmarks = {},
  }
  M.save_history()
  vim.notify("Cleared all history", vim.log.levels.INFO)
end

--- Clear recent history only
function M.clear_recent()
  M.history.recent = {}
  M.save_history()
  vim.notify("Cleared recent history", vim.log.levels.INFO)
end

--- Clear search history only
function M.clear_searches()
  M.history.searches = {}
  M.save_history()
  vim.notify("Cleared search history", vim.log.levels.INFO)
end

--- Get formatted history for display
-- @param limit number|nil Maximum number of entries
-- @return table Formatted history entries
function M.get_formatted_recent(limit)
  local recent = M.get_recent(limit)
  local formatted = {}

  for _, entry in ipairs(recent) do
    local time_str = os.date("%m/%d %H:%M", entry.timestamp)
    local display = string.format(
      "%s %s - %s (%s)",
      entry.resource_type == "resource" and "🏗️" or "📊",
      entry.resource_name,
      entry.description and entry.description:sub(1, 50) or "",
      time_str
    )

    table.insert(formatted, {
      display = display,
      resource_type = entry.resource_type,
      resource_name = entry.resource_name,
      timestamp = entry.timestamp,
    })
  end

  return formatted
end

return M
