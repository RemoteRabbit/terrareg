--- Test framework initialization for terrareg.nvim
-- @module tests.init

local M = {}

-- Test configuration
M.config = {
  test_dir = "/home/remoterabbit/repos/open/terrareg/tests",
  fixtures_dir = "/home/remoterabbit/repos/open/terrareg/tests/fixtures",
  mocks_dir = "/home/remoterabbit/repos/open/terrareg/tests/mocks",
  output_dir = "/home/remoterabbit/repos/open/terrareg/tests/output",
}

-- Test results tracking
M.results = {
  passed = 0,
  failed = 0,
  total = 0,
  failures = {},
}

--- Mock vim environment for testing
function M.setup_vim_mock()
  vim = vim or {}
  vim.fn = vim.fn or {}
  vim.loop = vim.loop or {}
  vim.log = vim.log or {}
  vim.log.levels = vim.log.levels or { INFO = 1, WARN = 2, ERROR = 3, DEBUG = 4 }
  vim.o = vim.o or { columns = 160, lines = 50 }
  vim.api = vim.api or {}
  vim.schedule = vim.schedule or function(fn)
    fn()
  end
  vim.notify = vim.notify or function(msg, level) end
  vim.keymap = vim.keymap or {}
  vim.keymap.set = vim.keymap.set or function() end
  vim.cmd = vim.cmd or function() end
  vim.tbl_deep_extend = vim.tbl_deep_extend
    or function(behavior, ...)
      local ret = {}
      for _, tbl in ipairs({ ... }) do
        for k, v in pairs(tbl) do
          ret[k] = v
        end
      end
      return ret
    end

  -- Mock file system operations
  vim.fn.mkdir = vim.fn.mkdir or function()
    return 1
  end
  vim.fn.writefile = vim.fn.writefile or function()
    return 0
  end
  vim.fn.readfile = vim.fn.readfile or function()
    return {}
  end
  vim.fn.filereadable = vim.fn.filereadable or function()
    return 1
  end
  vim.fn.system = vim.fn.system or function()
    return ""
  end
  vim.fn.input = vim.fn.input or function()
    return ""
  end

  -- Mock clipboard
  vim.fn.setreg = vim.fn.setreg or function() end
  vim.fn.getreg = vim.fn.getreg or function()
    return ""
  end
end

--- Assert functions for testing
function M.assert_equal(expected, actual, message)
  M.results.total = M.results.total + 1
  if expected == actual then
    M.results.passed = M.results.passed + 1
    return true
  else
    M.results.failed = M.results.failed + 1
    local failure = {
      message = message or "Assertion failed",
      expected = expected,
      actual = actual,
    }
    table.insert(M.results.failures, failure)
    return false
  end
end

function M.assert_true(condition, message)
  return M.assert_equal(true, condition, message)
end

function M.assert_false(condition, message)
  return M.assert_equal(false, condition, message)
end

function M.assert_not_nil(value, message)
  M.results.total = M.results.total + 1
  if value ~= nil then
    M.results.passed = M.results.passed + 1
    return true
  else
    M.results.failed = M.results.failed + 1
    table.insert(M.results.failures, {
      message = message or "Value should not be nil",
      expected = "not nil",
      actual = "nil",
    })
    return false
  end
end

function M.assert_type(expected_type, value, message)
  return M.assert_equal(expected_type, type(value), message)
end

--- Run a test function safely
function M.run_test(test_name, test_func)
  print(string.format("Running test: %s", test_name))
  local ok, err = pcall(test_func)
  if not ok then
    M.results.failed = M.results.failed + 1
    M.results.total = M.results.total + 1
    table.insert(M.results.failures, {
      message = string.format("Test '%s' threw an error", test_name),
      expected = "no error",
      actual = err,
    })
    print(string.format("  ✗ FAILED: %s", err))
  else
    print(string.format("  ✓ PASSED"))
  end
end

--- Print test results summary
function M.print_results()
  print("\n" .. string.rep("=", 60))
  print("TEST RESULTS SUMMARY")
  print(string.rep("=", 60))
  print(string.format("Total tests: %d", M.results.total))
  print(string.format("Passed: %d", M.results.passed))
  print(string.format("Failed: %d", M.results.failed))

  if #M.results.failures > 0 then
    print("\nFAILURES:")
    for i, failure in ipairs(M.results.failures) do
      print(string.format("%d. %s", i, failure.message))
      print(string.format("   Expected: %s", tostring(failure.expected)))
      print(string.format("   Actual: %s", tostring(failure.actual)))
    end
  end

  local success_rate = M.results.total > 0 and (M.results.passed / M.results.total * 100) or 0
  print(string.format("\nSuccess rate: %.1f%%", success_rate))
  print(string.rep("=", 60))
end

--- Reset test results
function M.reset()
  M.results = {
    passed = 0,
    failed = 0,
    total = 0,
    failures = {},
  }
end

return M
