# Examples

Real-world examples of using terrareg in different scenarios.

## Basic Examples

### Simple Setup

The most basic terrareg setup:

```lua
-- init.lua
require("terrareg").setup()
```

### Custom Configuration

Setting up terrareg with custom options:

```lua
-- init.lua
require("terrareg").setup({
  option1 = false,
  option2 = "custom_mode",
  debug = true,
})
```

## Plugin Manager Examples

### lazy.nvim Configuration

```lua
-- plugins/terrareg.lua
return {
  "remoterabbit/terrareg",
  opts = {
    option1 = true,
    option2 = "lazy_mode",
    debug = false,
  },
}
```

### Conditional Loading with lazy.nvim

```lua
-- plugins/terrareg.lua
return {
  "remoterabbit/terrareg",
  event = "VeryLazy",
  cmd = { "TerraregToggle", "TerraregStatus" },
  keys = {
    { "<leader>tr", "<cmd>TerraregToggle<cr>", desc = "Toggle Terrareg" },
  },
  opts = {
    option1 = true,
    option2 = "on_demand",
    debug = vim.env.DEBUG == "1",
  },
}
```

### packer.nvim Configuration

```lua
-- plugins.lua
use {
  "remoterabbit/terrareg",
  config = function()
    require("terrareg").setup({
      option1 = true,
      option2 = "packer_mode",
      debug = false,
    })
  end,
  requires = {
    -- Add any dependencies here
  },
}
```

## Environment-Specific Configurations

### Development vs Production

```lua
-- init.lua
local function get_env_config()
  local env = vim.env.NODE_ENV or "production"

  local configs = {
    development = {
      option1 = true,
      option2 = "dev",
      debug = true,
    },
    production = {
      option1 = true,
      option2 = "prod",
      debug = false,
    },
    testing = {
      option1 = false,
      option2 = "test",
      debug = true,
    },
  }

  return configs[env] or configs.production
end

require("terrareg").setup(get_env_config())
```

### Project-Specific Configuration

Create a project-specific configuration:

```lua
-- .nvimrc.lua (in project root)
local project_config = {
  option1 = false,
  option2 = "project_specific",
  debug = true,
}

-- Load terrareg with project config
require("terrareg").setup(project_config)
```

Then in your main config:

```lua
-- init.lua
-- Try to load project-specific config first
local project_config_path = vim.fn.getcwd() .. "/.nvimrc.lua"
if vim.fn.filereadable(project_config_path) == 1 then
  dofile(project_config_path)
else
  -- Fallback to default configuration
  require("terrareg").setup()
end
```

## Integration Examples

### With Telescope

```lua
-- Custom telescope picker for terrareg
local function terrareg_picker()
  local config = require("terrareg").get_config()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  pickers.new({}, {
    prompt_title = "Terrareg Configuration",
    finder = finders.new_table({
      results = {
        { "option1", tostring(config.option1) },
        { "option2", config.option2 },
        { "debug", tostring(config.debug) },
      },
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[1] .. ": " .. entry[2],
          ordinal = entry[1],
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
  }):find()
end

-- Key mapping
vim.keymap.set('n', '<leader>tc', terrareg_picker, { desc = 'Terrareg Config' })
```

### With Which-Key

```lua
-- which-key integration
local wk = require("which-key")

wk.register({
  t = {
    name = "Terrareg",
    r = { function()
      require("terrareg").setup({ option1 = not require("terrareg").get_config().option1 })
    end, "Toggle Option1" },
    s = { function()
      print(vim.inspect(require("terrareg").get_config()))
    end, "Show Status" },
    d = { function()
      local config = require("terrareg").get_config()
      require("terrareg").setup({ debug = not config.debug })
      print("Debug mode:", not config.debug)
    end, "Toggle Debug" },
  },
}, { prefix = "<leader>" })
```

## Advanced Examples

### Dynamic Configuration Based on File Type

```lua
-- init.lua
require("terrareg").setup({
  option1 = true,
  option2 = "default",
  debug = false,
})

-- Adjust configuration based on file type
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TerraregFileType", { clear = true }),
  callback = function(args)
    local ft = args.match
    local config_overrides = {
      lua = { option2 = "lua_mode" },
      python = { option2 = "python_mode" },
      javascript = { option2 = "js_mode" },
    }

    if config_overrides[ft] then
      require("terrareg").setup(config_overrides[ft])
    end
  end,
})
```

### Configuration with User Commands

```lua
-- Create user commands for terrareg
vim.api.nvim_create_user_command('TerraregToggle', function()
  local config = require("terrareg").get_config()
  require("terrareg").setup({ option1 = not config.option1 })
  print("Terrareg option1:", not config.option1)
end, { desc = 'Toggle Terrareg option1' })

vim.api.nvim_create_user_command('TerraregStatus', function()
  print(vim.inspect(require("terrareg").get_config()))
end, { desc = 'Show Terrareg status' })

vim.api.nvim_create_user_command('TerraregDebug', function(opts)
  local enable = opts.args == "on"
  require("terrareg").setup({ debug = enable })
  print("Terrareg debug:", enable)
end, {
  nargs = 1,
  complete = function() return { "on", "off" } end,
  desc = 'Toggle Terrareg debug mode'
})
```

### Configuration Persistence

```lua
-- Save/load configuration to/from file
local config_file = vim.fn.stdpath("data") .. "/terrareg_config.json"

local function save_config()
  local config = require("terrareg").get_config()
  local file = io.open(config_file, "w")
  if file then
    file:write(vim.fn.json_encode(config))
    file:close()
    print("Configuration saved")
  end
end

local function load_config()
  local file = io.open(config_file, "r")
  if file then
    local content = file:read("*all")
    file:close()
    local config = vim.fn.json_decode(content)
    require("terrareg").setup(config)
    print("Configuration loaded")
  else
    require("terrareg").setup()  -- Use defaults
  end
end

-- Load configuration on startup
load_config()

-- Commands to save/load
vim.api.nvim_create_user_command('TerraregSave', save_config, {})
vim.api.nvim_create_user_command('TerraregLoad', load_config, {})
```

## Troubleshooting Examples

### Debug Configuration Issues

```lua
-- Helper function to debug configuration
local function debug_terrareg()
  local ok, config = pcall(require("terrareg").get_config)
  if not ok then
    print("❌ Terrareg not initialized")
    return
  end

  print("✅ Terrareg Configuration:")
  print("  option1:", config.option1)
  print("  option2:", config.option2)
  print("  debug:", config.debug)

  -- Validate configuration
  local issues = {}
  if type(config.option1) ~= "boolean" then
    table.insert(issues, "option1 should be boolean")
  end
  if type(config.option2) ~= "string" then
    table.insert(issues, "option2 should be string")
  end
  if type(config.debug) ~= "boolean" then
    table.insert(issues, "debug should be boolean")
  end

  if #issues > 0 then
    print("⚠️  Configuration issues:")
    for _, issue in ipairs(issues) do
      print("  -", issue)
    end
  else
    print("✅ Configuration is valid")
  end
end

-- Create command
vim.api.nvim_create_user_command('TerraregDebugConfig', debug_terrareg, {})
```

### Safe Configuration Loading

```lua
-- Safely load terrareg with error handling
local function safe_setup(config)
  local ok, err = pcall(require("terrareg").setup, config)
  if not ok then
    print("❌ Error setting up terrareg:", err)
    -- Fallback to default configuration
    require("terrareg").setup()
    print("✅ Loaded with default configuration")
  else
    print("✅ Terrareg configured successfully")
  end
end

-- Use safe setup
safe_setup({
  option1 = true,
  option2 = "safe_mode",
  debug = false,
})
```

::: tip Example Best Practices
1. Always test configurations before committing
2. Use environment variables for different setups
3. Create helper functions for complex configurations
4. Add error handling for production use
5. Document your custom setups
:::
