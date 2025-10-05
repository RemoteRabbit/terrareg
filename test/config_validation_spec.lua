-- Tests for configuration validation
local helpers = require("test.helpers")

describe("config validation", function()
  local config_validation

  before_each(function()
    helpers.reset_plugin()
    helpers.mock_vim_functions()
    config_validation = require("terrareg.config_validation")
  end)

  after_each(function()
    helpers.restore_vim_functions()
  end)

  describe("module loading", function()
    it("should load without errors", function()
      assert.is_not_nil(config_validation)
      assert.equals("table", type(config_validation))
    end)

    it("should have required functions", function()
      assert.is_function(config_validation.validate_config)
      assert.is_function(config_validation.get_default_config)
    end)
  end)

  describe("validate_config function", function()
    it("should accept valid configuration", function()
      local config = {
        option1 = true,
        option2 = "test",
        debug = false,
      }

      local valid, err = config_validation.validate_config(config)

      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should reject non-table configuration", function()
      local valid, err = config_validation.validate_config("not a table")

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches("must be a table", err)
    end)

    it("should reject nil configuration", function()
      local valid, err = config_validation.validate_config(nil)

      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it("should validate boolean fields", function()
      local config = { option1 = "not a boolean" }
      local valid, err = config_validation.validate_config(config)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches("option1.*boolean", err)
    end)

    it("should validate string fields", function()
      local config = { option2 = 123 }
      local valid, err = config_validation.validate_config(config)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches("option2.*string", err)
    end)

    it("should allow nil values for optional fields", function()
      local config = { option1 = true } -- missing other fields
      local valid, err = config_validation.validate_config(config)

      -- Should be valid since fields are optional
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should handle empty configuration", function()
      local valid, err = config_validation.validate_config({})

      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should validate debug field", function()
      local config = { debug = "not a boolean" }
      local valid, err = config_validation.validate_config(config)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches("debug.*boolean", err)
    end)

    it("should allow all valid combinations", function()
      local test_configs = {
        { option1 = true, option2 = "test", debug = false },
        { option1 = false, option2 = "custom", debug = true },
        { option1 = true },
        { option2 = "only_string" },
        { debug = true },
        {},
      }

      for _, config in ipairs(test_configs) do
        local valid, err = config_validation.validate_config(config)
        assert.is_true(valid, "Config should be valid: " .. vim.inspect(config))
        assert.is_nil(err)
      end
    end)
  end)

  describe("get_default_config function", function()
    it("should return a table", function()
      local default_config = config_validation.get_default_config()

      assert.is_not_nil(default_config)
      assert.equals("table", type(default_config))
    end)

    it("should have expected default values", function()
      local default_config = config_validation.get_default_config()

      -- Check types and values match what we expect
      assert.equals("boolean", type(default_config.option1))
      assert.equals("string", type(default_config.option2))
      assert.equals("boolean", type(default_config.debug))
    end)

    it("should return consistent values", function()
      local config1 = config_validation.get_default_config()
      local config2 = config_validation.get_default_config()

      helpers.assert_table_equals(config1, config2)
    end)

    it("should pass its own validation", function()
      local default_config = config_validation.get_default_config()
      local valid, err = config_validation.validate_config(default_config)

      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should be safe to modify returned table", function()
      local default_config = config_validation.get_default_config()

      -- Modify the returned table
      default_config.option1 = false
      default_config.new_field = "test"

      -- Get a fresh copy
      local fresh_config = config_validation.get_default_config()

      -- Should not be affected by modifications
      assert.is_not_nil(fresh_config.option1)
      assert.is_nil(fresh_config.new_field)
    end)
  end)

  describe("integration with main module", function()
    it("should validate terrareg default config", function()
      local terrareg = require("terrareg")
      local valid, err = config_validation.validate_config(terrareg.config)

      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should validate config after setup", function()
      local terrareg = require("terrareg")
      terrareg.setup({ option1 = false, debug = true })

      local valid, err = config_validation.validate_config(terrareg.config)

      assert.is_true(valid)
      assert.is_nil(err)
    end)
  end)
end)
