--- In-document search and navigation for terrareg.nvim
-- @module terrareg.search

local M = {}

-- Search state
M.state = {
  current_query = "",
  current_matches = {},
  current_match_index = 0,
  buffer = nil,
  window = nil,
  namespace = nil,
}

--- Initialize search system
function M.setup()
  M.state.namespace = vim.api.nvim_create_namespace("terrareg_search")
end

--- Start search in documentation window
-- @param buffer number Buffer number
-- @param window number Window number
function M.start_search(buffer, window)
  M.state.buffer = buffer
  M.state.window = window

  -- Prompt for search query
  vim.ui.input({
    prompt = "Search: ",
    default = M.state.current_query,
  }, function(query)
    if query and query ~= "" then
      M.search(query)
    end
  end)
end

--- Perform search in the documentation
-- @param query string Search query
function M.search(query)
  if not M.state.buffer or not vim.api.nvim_buf_is_valid(M.state.buffer) then
    return
  end

  M.state.current_query = query
  M.state.current_matches = {}
  M.state.current_match_index = 0

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(M.state.buffer, M.state.namespace, 0, -1)

  -- Get all lines from buffer
  local lines = vim.api.nvim_buf_get_lines(M.state.buffer, 0, -1, false)

  -- Search for matches (case-insensitive)
  local lower_query = query:lower()
  for line_num, line in ipairs(lines) do
    local lower_line = line:lower()
    local start_pos = 1

    while true do
      local match_start, match_end = lower_line:find(lower_query, start_pos, true)
      if not match_start then
        break
      end

      table.insert(M.state.current_matches, {
        line = line_num - 1, -- 0-indexed for nvim API
        col_start = match_start - 1, -- 0-indexed for nvim API
        col_end = match_end,
      })

      -- Highlight the match
      vim.api.nvim_buf_add_highlight(
        M.state.buffer,
        M.state.namespace,
        "Search",
        line_num - 1,
        match_start - 1,
        match_end
      )

      start_pos = match_end + 1
    end
  end

  -- Jump to first match
  if #M.state.current_matches > 0 then
    M.state.current_match_index = 1
    M.jump_to_current_match()

    -- Show match count
    vim.notify(string.format("Found %d matches", #M.state.current_matches), vim.log.levels.INFO)
  else
    vim.notify("No matches found", vim.log.levels.WARN)
  end
end

--- Jump to the current match
function M.jump_to_current_match()
  if
    #M.state.current_matches == 0
    or not M.state.window
    or not vim.api.nvim_win_is_valid(M.state.window)
  then
    return
  end

  local match = M.state.current_matches[M.state.current_match_index]
  if match then
    -- Move cursor to match
    vim.api.nvim_win_set_cursor(M.state.window, { match.line + 1, match.col_start })

    -- Center the match in the window
    vim.api.nvim_win_call(M.state.window, function()
      vim.cmd("normal! zz")
    end)

    -- Highlight current match differently
    M.highlight_current_match(match)

    -- Show position info
    vim.notify(
      string.format("Match %d of %d", M.state.current_match_index, #M.state.current_matches),
      vim.log.levels.INFO
    )
  end
end

--- Highlight the current match with a different color
-- @param match table Match information
function M.highlight_current_match(match)
  -- Clear previous current match highlight
  vim.api.nvim_buf_clear_namespace(M.state.buffer, M.state.namespace + 1, 0, -1)

  -- Highlight current match
  vim.api.nvim_buf_add_highlight(
    M.state.buffer,
    M.state.namespace + 1,
    "IncSearch",
    match.line,
    match.col_start,
    match.col_end
  )
end

--- Move to next search match
function M.next_match()
  if #M.state.current_matches == 0 then
    vim.notify("No search matches", vim.log.levels.WARN)
    return
  end

  M.state.current_match_index = M.state.current_match_index + 1
  if M.state.current_match_index > #M.state.current_matches then
    M.state.current_match_index = 1 -- Wrap around
  end

  M.jump_to_current_match()
end

--- Move to previous search match
function M.prev_match()
  if #M.state.current_matches == 0 then
    vim.notify("No search matches", vim.log.levels.WARN)
    return
  end

  M.state.current_match_index = M.state.current_match_index - 1
  if M.state.current_match_index < 1 then
    M.state.current_match_index = #M.state.current_matches -- Wrap around
  end

  M.jump_to_current_match()
end

--- Clear search highlights
function M.clear_search()
  if M.state.buffer and vim.api.nvim_buf_is_valid(M.state.buffer) then
    vim.api.nvim_buf_clear_namespace(M.state.buffer, M.state.namespace, 0, -1)
    vim.api.nvim_buf_clear_namespace(M.state.buffer, M.state.namespace + 1, 0, -1)
  end

  M.state.current_query = ""
  M.state.current_matches = {}
  M.state.current_match_index = 0
end

--- Jump to specific argument by letter
-- @param letter string Single letter to jump to
function M.jump_to_argument(letter)
  if not M.state.buffer or not vim.api.nvim_buf_is_valid(M.state.buffer) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(M.state.buffer, 0, -1, false)
  local target_line = nil

  -- Look for arguments starting with the letter
  for line_num, line in ipairs(lines) do
    -- Match table rows with argument names
    local arg_match = line:match("│%s*([a-zA-Z_][a-zA-Z0-9_]*)")
    if arg_match and arg_match:lower():sub(1, 1) == letter:lower() then
      target_line = line_num
      break
    end
  end

  if target_line and M.state.window and vim.api.nvim_win_is_valid(M.state.window) then
    vim.api.nvim_win_set_cursor(M.state.window, { target_line, 0 })
    vim.api.nvim_win_call(M.state.window, function()
      vim.cmd("normal! zz")
    end)
    vim.notify(string.format("Jumped to argument starting with '%s'", letter), vim.log.levels.INFO)
  else
    vim.notify(string.format("No argument found starting with '%s'", letter), vim.log.levels.WARN)
  end
end

--- Setup search keymaps for documentation buffer
-- @param buffer number Buffer number
-- @param window number Window number
function M.setup_keymaps(buffer, window)
  local opts = { noremap = true, silent = true, buffer = buffer }

  -- Search commands
  vim.keymap.set("n", "/", function()
    M.start_search(buffer, window)
  end, opts)
  vim.keymap.set("n", "n", M.next_match, opts)
  vim.keymap.set("n", "N", M.prev_match, opts)
  vim.keymap.set("n", "<Esc>", M.clear_search, opts)

  -- Quick jump to arguments
  for i = string.byte("a"), string.byte("z") do
    local letter = string.char(i)
    vim.keymap.set("n", "g" .. letter, function()
      M.jump_to_argument(letter)
    end, opts)
  end
end

return M
