-- Integration tests for terrareg with Neovim
-- luacheck: globals vim describe it before_each assert pending
local helpers = require("test.helpers")

-- Only run integration tests if we're in a Neovim environment
if not vim.api then
  pending("Integration tests require Neovim API")
  return
end

describe("terrareg integration", function()
  local terrareg

  before_each(function()
    helpers.reset_plugin()

    -- Ensure we have a clean Neovim state
    vim.cmd("silent! buffers")

    terrareg = require("terrareg")
  end)

  describe("plugin loading in Neovim", function()
    it("should work with real vim.tbl_deep_extend", function()
      -- Test that our plugin works with the real Neovim function
      assert.is_function(vim.tbl_deep_extend)

      local config = {
        option1 = false,
        option2 = "custom",
      }

      assert.has_no_errors(function()
        terrareg.setup(config)
      end)

      assert.equals(false, terrareg.config.option1)
      assert.equals("custom", terrareg.config.option2)
    end)

    it("should handle Neovim global variables", function()
      -- Test interaction with Neovim globals
      vim.g.test_variable = "test_value"

      assert.has_no_errors(function()
        terrareg.setup({ debug = true })
      end)

      -- Should not interfere with Neovim globals
      assert.equals("test_value", vim.g.test_variable)

      -- Cleanup
      vim.g.test_variable = nil
    end)

    it("should work with vim.inspect for debug output", function()
      -- Test that debug mode can use vim.inspect
      terrareg.setup({ debug = true })

      assert.is_function(vim.inspect)
      assert.has_no_errors(function()
        local output = vim.inspect(terrareg.config)
        assert.is_string(output)
        assert.matches("option1", output)
      end)
    end)
  end)

  describe("buffer operations", function()
    local test_buf

    before_each(function()
      test_buf = helpers.create_test_buffer({ "line 1", "line 2", "line 3" })
    end)

    after_each(function()
      helpers.cleanup_buffer(test_buf)
    end)

    it("should work with Neovim buffers", function()
      assert.is_number(test_buf)
      assert.is_true(vim.api.nvim_buf_is_valid(test_buf))

      local lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
      assert.equals(3, #lines)
      assert.equals("line 1", lines[1])
    end)

    it("should not interfere with buffer operations", function()
      -- Setup our plugin
      terrareg.setup({ option1 = false })

      -- Buffer operations should still work
      vim.api.nvim_buf_set_lines(test_buf, 0, 1, false, { "modified line" })

      local lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
      assert.equals("modified line", lines[1])
      assert.equals("line 2", lines[2])
    end)
  end)

  describe("autocommands and events", function()
    it("should handle Neovim autocommands if plugin creates any", function()
      -- Test that plugin doesn't break autocommand system
      local autocmd_fired = false

      -- Create a test autocommand
      vim.api.nvim_create_autocmd("User", {
        pattern = "TestEvent",
        callback = function()
          autocmd_fired = true
        end,
      })

      -- Setup plugin
      terrareg.setup()

      -- Fire the test event
      vim.api.nvim_exec_autocmds("User", { pattern = "TestEvent" })

      -- Should still work
      assert.is_true(autocmd_fired)
    end)
  end)

  describe("command line and functions", function()
    it("should not interfere with vim commands", function()
      terrareg.setup()

      -- Basic vim commands should still work
      assert.has_no_errors(function()
        vim.cmd('echo "test"')
      end)
    end)

    it("should work with vim.fn functions", function()
      terrareg.setup()

      -- Test that vim.fn still works
      assert.is_function(vim.fn.expand)
      assert.has_no_errors(function()
        local result = vim.fn.expand("%")
        assert.is_string(result)
      end)
    end)
  end)

  describe("plugin state management", function()
    it("should handle multiple setup calls gracefully", function()
      -- Test that calling setup multiple times doesn't break Neovim
      terrareg.setup({ option1 = true })
      terrareg.setup({ option2 = "first" })
      terrareg.setup({ debug = true })

      local config = terrareg.get_config()
      assert.equals(true, config.option1)
      assert.equals("first", config.option2)
      assert.equals(true, config.debug)
    end)

    it("should maintain state across buffer switches", function()
      local buf1 = helpers.create_test_buffer({ "buffer 1" })
      local buf2 = helpers.create_test_buffer({ "buffer 2" })

      -- Setup plugin
      terrareg.setup({ option1 = false })

      -- Switch buffers
      vim.api.nvim_set_current_buf(buf1)
      local config1 = terrareg.get_config()

      vim.api.nvim_set_current_buf(buf2)
      local config2 = terrareg.get_config()

      -- Config should be the same regardless of buffer
      helpers.assert_table_equals(config1, config2)

      -- Cleanup
      helpers.cleanup_buffer(buf1)
      helpers.cleanup_buffer(buf2)
    end)
  end)

  describe("error handling in Neovim context", function()
    it("should handle vim.notify if available", function()
      if vim.notify then
        -- Test that errors can be displayed via vim.notify
        assert.is_function(vim.notify)

        assert.has_no_errors(function()
          vim.notify("Test notification", vim.log.levels.INFO)
        end)
      end
    end)

    it("should not break Neovim on invalid config", function()
      -- Even with invalid config, shouldn't crash Neovim
      assert.has_no_errors(function()
        terrareg.setup({ invalid_option = "should be ignored" })
      end)

      -- Neovim should still be functional
      assert.has_no_errors(function()
        vim.cmd('echo "still works"')
      end)
    end)
  end)

  describe("performance in Neovim", function()
    it("should setup quickly", function()
      local start_time = vim.loop.hrtime()

      terrareg.setup({
        option1 = false,
        option2 = "performance_test",
        debug = false,
      })

      local end_time = vim.loop.hrtime()
      local duration_ms = (end_time - start_time) / 1e6

      -- Setup should complete in reasonable time (< 10ms)
      assert.is_true(duration_ms < 10, string.format("Setup took too long: %.2fms", duration_ms))
    end)

    it("should not leak memory on repeated setup", function()
      -- Test that repeated setup calls don't accumulate memory
      local initial_memory = collectgarbage("count")

      for i = 1, 100 do
        terrareg.setup({ option1 = i % 2 == 0 })
      end

      collectgarbage("collect")
      local final_memory = collectgarbage("count")

      -- Memory usage shouldn't grow significantly
      local memory_growth = final_memory - initial_memory
      assert.is_true(
        memory_growth < 100,
        string.format("Memory growth too large: %.2f KB", memory_growth)
      )
    end)
  end)
end)
