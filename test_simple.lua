-- Simple test runner to verify our plugin works

-- Mock vim.tbl_deep_extend for testing outside Neovim
if not _G.vim then
  _G.vim = {
    tbl_deep_extend = function(_, ...)
      local result = {}
      for _, tbl in ipairs({ ... }) do
        if type(tbl) == "table" then
          for k, v in pairs(tbl) do
            result[k] = v
          end
        end
      end
      return result
    end,
  }
end

local terrareg = require("terrareg")

print("🧪 Running simple tests...")

-- Test 1: Module loads
assert(terrareg ~= nil, "Module should load")
print("✅ Module loads")

-- Test 2: Has required functions
assert(type(terrareg.setup) == "function", "Should have setup function")
assert(type(terrareg.get_config) == "function", "Should have get_config function")
print("✅ Has required functions")

-- Test 3: Default config
local default_config = terrareg.config
assert(default_config.option1 == true, "Default option1 should be true")
assert(default_config.option2 == "default", "Default option2 should be 'default'")
assert(default_config.debug == false, "Default debug should be false")
print("✅ Default config correct")

-- Test 4: Setup works
terrareg.setup({ option1 = false, debug = true })
assert(terrareg.config.option1 == false, "option1 should be updated")
assert(terrareg.config.debug == true, "debug should be updated")
assert(terrareg.config.option2 == "default", "option2 should remain default")
print("✅ Setup works")

-- Test 5: get_config works
local config = terrareg.get_config()
assert(config == terrareg.config, "get_config should return same reference")
print("✅ get_config works")

-- Test 6: Configuration validation
local config_validation = require("terrareg.config_validation")
assert(config_validation ~= nil, "Config validation module should load")
local valid, err = config_validation.validate_config(terrareg.config)
assert(valid == true, "Current config should be valid")
assert(err == nil, "Should have no error")
print("✅ Configuration validation works")

print("🎉 All tests passed!")
