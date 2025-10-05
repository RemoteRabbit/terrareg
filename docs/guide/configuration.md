# Configuration

terrareg is highly configurable to fit your specific workflow needs. This guide covers all available configuration options.

## Default Configuration

```lua
require("terrareg").setup({
  option1 = true,
  option2 = "default",
  debug = false,
})
```

## Configuration Options

### Core Options

#### `option1`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Controls the primary feature of terrareg

```lua
require("terrareg").setup({
  option1 = false,  -- Disable the main feature
})
```

#### `option2`
- **Type**: `string`
- **Default**: `"default"`
- **Description**: Sets the operational mode for terrareg

```lua
require("terrareg").setup({
  option2 = "custom_mode",  -- Use custom operational mode
})
```

#### `debug`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enables debug logging and verbose output

```lua
require("terrareg").setup({
  debug = true,  -- Enable debug mode
})
```

## Configuration Patterns

### Environment-Based Configuration

```lua
local config = {
  debug = false,
  option1 = true,
  option2 = "production",
}

-- Enable debug mode in development
if vim.env.NODE_ENV == "development" then
  config.debug = true
  config.option2 = "development"
end

require("terrareg").setup(config)
```

### Project-Specific Configuration

Create a `.nvim.lua` file in your project root:

```lua
-- .nvim.lua
return {
  terrareg = {
    option1 = false,
    option2 = "project_specific",
    debug = true,
  }
}
```

Then in your `init.lua`:

```lua
-- Load project-specific config if available
local ok, project_config = pcall(require, ".nvim")
local terrareg_config = ok and project_config.terrareg or {}

require("terrareg").setup(terrareg_config)
```

### Conditional Configuration

```lua
local config = {
  option1 = true,
  option2 = "default",
  debug = false,
}

-- Adjust based on file type
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "vim" },
  callback = function()
    -- File-type specific adjustments
    local current_config = require("terrareg").get_config()
    if current_config.option2 == "default" then
      require("terrareg").setup({
        option2 = "lua_mode",
      })
    end
  end,
})

require("terrareg").setup(config)
```

## Advanced Configuration

### Dynamic Configuration Updates

You can update configuration at runtime:

```lua
-- Initial setup
require("terrareg").setup({
  option1 = true,
  debug = false,
})

-- Later, update specific options
require("terrareg").setup({
  debug = true,  -- This will merge with existing config
})
```

### Configuration Validation

terrareg validates your configuration automatically. Invalid configurations will show helpful error messages:

```lua
-- This will show an error if option2 expects specific values
require("terrareg").setup({
  option2 = "invalid_value",  -- Error: invalid value for option2
})
```

### Getting Current Configuration

```lua
-- Get the current configuration
local config = require("terrareg").get_config()
print(vim.inspect(config))

-- Check specific option
if config.debug then
  print("Debug mode is enabled")
end
```

## Configuration Examples

### Minimal Setup
```lua
require("terrareg").setup()
```

### Development Setup
```lua
require("terrareg").setup({
  debug = true,
  option1 = true,
  option2 = "development",
})
```

### Production Setup
```lua
require("terrareg").setup({
  debug = false,
  option1 = true,
  option2 = "production",
})
```

### Custom Workflow Setup
```lua
require("terrareg").setup({
  option1 = false,
  option2 = "custom_workflow",
  debug = vim.env.DEBUG == "1",  -- Enable debug via environment variable
})
```

## Configuration Schema

For reference, here's the complete configuration schema:

```typescript
interface TerraregConfig {
  option1: boolean;      // Primary feature toggle
  option2: string;       // Operational mode
  debug: boolean;        // Debug mode toggle
}
```

## Troubleshooting Configuration

### Validating Your Configuration

```lua
-- Check if your configuration is valid
local config = require("terrareg").get_config()
if config.debug then
  print("Configuration loaded successfully:")
  print(vim.inspect(config))
end
```

### Common Configuration Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Configuration not taking effect | Missing setup call | Ensure `require("terrareg").setup()` is called |
| Type errors | Wrong value type | Check the expected type for each option |
| Invalid values | Unsupported option value | Use valid values as documented |

### Reset to Defaults

```lua
-- Reset to default configuration
require("terrareg").setup({
  option1 = true,
  option2 = "default",
  debug = false,
})
```

::: tip Configuration Best Practices
1. Start with default configuration
2. Change one option at a time
3. Test each change thoroughly
4. Use environment variables for different setups
5. Document your custom configuration
:::

::: warning Important Notes
- Configuration changes require calling `setup()` again
- Some options may require restarting Neovim
- Invalid configurations will show error messages
:::
