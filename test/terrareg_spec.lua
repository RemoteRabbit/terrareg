-- Tests for terrareg main module
local helpers = require("test.helpers")

describe("terrareg", function()
  local terrareg

  before_each(function()
    helpers.reset_plugin()
    helpers.mock_vim_functions()
    terrareg = require("terrareg")
  end)

  after_each(function()
    helpers.restore_vim_functions()
  end)

  describe("module loading", function()
    it("should load without errors", function()
      assert.is_not_nil(terrareg)
      assert.equals("table", type(terrareg))
    end)

    it("should have required functions", function()
      assert.is_function(terrareg.setup)
      assert.is_function(terrareg.get_config)
    end)

    it("should have default config", function()
      assert.is_not_nil(terrareg.config)
      assert.equals("table", type(terrareg.config))
    end)
  end)

  describe("default configuration", function()
    it("should have correct default values", function()
      local expected_config = {
        option1 = true,
        option2 = "default",
        debug = false,
      }

      helpers.assert_table_equals(expected_config, terrareg.config)
    end)

    it("should have all required fields", function()
      assert.is_not_nil(terrareg.config.option1)
      assert.is_not_nil(terrareg.config.option2)
      assert.is_not_nil(terrareg.config.debug)
    end)

    it("should have correct field types", function()
      assert.equals("boolean", type(terrareg.config.option1))
      assert.equals("string", type(terrareg.config.option2))
      assert.equals("boolean", type(terrareg.config.debug))
    end)
  end)

  describe("setup function", function()
    it("should work with no arguments", function()
      assert.has_no_errors(function()
        terrareg.setup()
      end)
    end)

    it("should work with nil argument", function()
      assert.has_no_errors(function()
        terrareg.setup(nil)
      end)
    end)

    it("should work with empty table", function()
      assert.has_no_errors(function()
        terrareg.setup({})
      end)
    end)

    it("should merge user config with defaults", function()
      local user_config = {
        option1 = false,
        debug = true,
      }

      terrareg.setup(user_config)

      -- Should merge user config
      assert.equals(false, terrareg.config.option1)
      assert.equals(true, terrareg.config.debug)

      -- Should keep defaults for unspecified options
      assert.equals("default", terrareg.config.option2)
    end)

    it("should handle partial configuration", function()
      terrareg.setup({ option1 = false })

      assert.equals(false, terrareg.config.option1)
      assert.equals("default", terrareg.config.option2)
      assert.equals(false, terrareg.config.debug)
    end)

    it("should handle string values", function()
      terrareg.setup({ option2 = "custom_value" })

      assert.equals("custom_value", terrareg.config.option2)
    end)

    it("should handle nested configurations gracefully", function()
      -- Should not error on unexpected nested tables
      assert.has_no_errors(function()
        terrareg.setup({
          option1 = true,
          nested = { key = "value" },
        })
      end)
    end)
  end)

  describe("get_config function", function()
    it("should return current configuration", function()
      local config = terrareg.get_config()

      assert.is_not_nil(config)
      assert.equals("table", type(config))
    end)

    it("should return config with default values initially", function()
      local config = terrareg.get_config()

      assert.equals(true, config.option1)
      assert.equals("default", config.option2)
      assert.equals(false, config.debug)
    end)

    it("should return updated config after setup", function()
      terrareg.setup({ option1 = false, debug = true })
      local config = terrareg.get_config()

      assert.equals(false, config.option1)
      assert.equals(true, config.debug)
      assert.equals("default", config.option2)
    end)

    it("should return same reference as internal config", function()
      local config = terrareg.get_config()

      -- Should be the same table reference
      assert.equals(terrareg.config, config)
    end)
  end)

  describe("configuration persistence", function()
    it("should persist config changes", function()
      terrareg.setup({ option1 = false })

      -- Get config multiple times
      local config1 = terrareg.get_config()
      local config2 = terrareg.get_config()

      assert.equals(config1.option1, config2.option1)
      assert.equals(false, config1.option1)
    end)

    it("should allow multiple setup calls", function()
      terrareg.setup({ option1 = false })
      terrareg.setup({ debug = true })

      local config = terrareg.get_config()

      -- Should preserve previous changes
      assert.equals(false, config.option1)
      assert.equals(true, config.debug)
    end)
  end)

  describe("debug mode", function()
    it("should enable debug mode when requested", function()
      terrareg.setup({ debug = true })

      assert.equals(true, terrareg.config.debug)
    end)

    it("should disable debug mode by default", function()
      assert.equals(false, terrareg.config.debug)
    end)
  end)
end)
