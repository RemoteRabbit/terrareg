-- Test helpers for terrareg.nvim
-- luacheck: globals vim assert
local M = {}

-- Reset plugin state before each test
function M.reset_plugin()
  -- Clear any cached modules
  package.loaded["terrareg"] = nil
  package.loaded["terrareg.config_validation"] = nil

  -- Reset global state if any
  if vim.g.loaded_terrareg then
    vim.g.loaded_terrareg = nil
  end
end

-- Create a temporary configuration for testing
function M.temp_config(overrides)
  local default_config = {
    option1 = true,
    option2 = "default",
    debug = false,
  }

  if overrides then
    return vim.tbl_deep_extend("force", default_config, overrides)
  end

  return default_config
end

-- Mock vim functions if needed
function M.mock_vim_functions()
  -- Store original functions
  M._original_functions = {}

  -- Mock vim.tbl_deep_extend if not available
  if not vim.tbl_deep_extend then
    vim.tbl_deep_extend = function(_, ...)
      local tables = { ... }
      local result = {}

      for _, tbl in ipairs(tables) do
        if type(tbl) == "table" then
          for k, v in pairs(tbl) do
            result[k] = v
          end
        end
      end

      return result
    end
  end
end

-- Restore original vim functions
function M.restore_vim_functions()
  if M._original_functions then
    for name, func in pairs(M._original_functions) do
      vim[name] = func
    end
    M._original_functions = nil
  end
end

-- Create a test buffer
function M.create_test_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  if lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  return buf
end

-- Clean up test buffer
function M.cleanup_buffer(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Wait for condition (useful for async tests)
function M.wait_for(condition, timeout, interval)
  timeout = timeout or 1000
  interval = interval or 10
  local start_time = vim.loop.now()

  while vim.loop.now() - start_time < timeout do
    if condition() then
      return true
    end
    vim.wait(interval)
  end

  return false
end

-- Assert that a function throws an error
function M.assert_error(func, expected_pattern)
  local ok, err = pcall(func)
  assert.is_false(ok, "Expected function to throw an error")
  if expected_pattern then
    assert.matches(expected_pattern, err)
  end
end

-- Assert table equality with better error messages
function M.assert_table_equals(expected, actual, path)
  path = path or "root"

  assert.equals(
    type(expected),
    type(actual),
    string.format("Type mismatch at %s: expected %s, got %s", path, type(expected), type(actual))
  )

  if type(expected) == "table" then
    for k, v in pairs(expected) do
      local current_path = path .. "." .. tostring(k)
      assert.is_not_nil(actual[k], string.format("Missing key at %s", current_path))
      M.assert_table_equals(v, actual[k], current_path)
    end

    for k, _ in pairs(actual) do
      local current_path = path .. "." .. tostring(k)
      assert.is_not_nil(expected[k], string.format("Unexpected key at %s", current_path))
    end
  else
    assert.equals(expected, actual, string.format("Value mismatch at %s", path))
  end
end

-- Print debug information
function M.debug_print(...)
  if os.getenv("DEBUG_TESTS") then
    print("[TEST DEBUG]", ...)
  end
end

return M
