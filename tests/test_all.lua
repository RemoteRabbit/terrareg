--- Main test runner for terrareg.nvim
-- @module tests.test_all

package.path = "./lua/?.lua;./tests/?.lua;" .. package.path

-- Import all test modules
local test_parser = require("tests.test_parser")

-- Test modules to add as we implement features
local test_modules = {
  test_parser,
  -- test_http,
  -- test_docs,
  -- test_cache,
  -- test_display,
  -- test_telescope,
  -- test_search,
  -- test_bookmarks,
  -- test_multi_provider,
}

--- Run all tests
local function run_all_tests()
  print("🧪 TERRAREG.NVIM COMPREHENSIVE TEST SUITE")
  print("==========================================")
  print()

  for i, test_module in ipairs(test_modules) do
    if test_module.run then
      test_module.run()
      print()
    end
  end

  print("🏁 All tests completed!")
end

-- Run tests if called directly
if arg and arg[0] and arg[0]:match("test_all%.lua$") then
  run_all_tests()
end

return {
  run_all = run_all_tests,
}
