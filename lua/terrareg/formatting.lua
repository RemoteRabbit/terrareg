--- Formatting utilities for terrareg.nvim
-- @module terrareg.formatting

local M = {}

--- Wrap text at specified width
-- @param text string Text to wrap
-- @param width number Maximum line width
-- @return string Wrapped text
function M.wrap_text(text, width)
  width = width or 70
  if not text or text == "" then
    return ""
  end

  local wrapped = {}
  local current_line = ""

  for word in text:gmatch("%S+") do
    if #current_line + #word + 1 > width then
      if current_line ~= "" then
        table.insert(wrapped, current_line)
        current_line = word
      else
        table.insert(wrapped, word)
      end
    else
      current_line = current_line == "" and word or current_line .. " " .. word
    end
  end

  if current_line ~= "" then
    table.insert(wrapped, current_line)
  end

  return table.concat(wrapped, "\n")
end

--- Pad string to specific width, accounting for Unicode display width
-- @param str string String to pad
-- @param width number Target display width
-- @return string Padded string
function M.pad_string(str, width)
  local display_width = 0
  local byte_length = 0

  for i = 1, #str do
    local byte = string.byte(str, i)
    if byte < 128 then
      display_width = display_width + 1
    elseif byte >= 194 and byte <= 244 then
      display_width = display_width + 1
    end
    byte_length = i
  end

  local padding_needed = width - display_width
  if padding_needed <= 0 then
    return str
  end

  return str .. string.rep(" ", padding_needed)
end

return M
