# API Reference

This section provides comprehensive documentation for the terrareg API.

## Core Module

### `require("terrareg")`

The main module that provides the core functionality.

```lua
local terrareg = require("terrareg")
```

## Functions

### `setup(opts?)`

Initializes terrareg with the provided configuration.

**Parameters:**
- `opts` (`table?`) - Configuration options (optional)

**Returns:**
- `void`

**Example:**
```lua
require("terrareg").setup({
  option1 = false,
  option2 = "custom",
  debug = true,
})
```

### `get_config()`

Returns the current configuration.

**Parameters:**
- None

**Returns:**
- `table` - Current configuration object

**Example:**
```lua
local config = require("terrareg").get_config()
print("Current debug mode:", config.debug)
```

## Configuration Object

### Properties

#### `config.option1`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Primary feature toggle

#### `config.option2`
- **Type**: `string`
- **Default**: `"default"`
- **Description**: Operational mode setting

#### `config.debug`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Debug mode toggle

## Usage Examples

### Basic Setup
```lua
-- Initialize with defaults
require("terrareg").setup()

-- Get current configuration
local config = require("terrareg").get_config()
```

### Custom Configuration
```lua
-- Setup with custom options
require("terrareg").setup({
  option1 = false,
  option2 = "production",
  debug = false,
})

-- Verify configuration
local config = require("terrareg").get_config()
assert(config.option1 == false)
assert(config.option2 == "production")
```

### Runtime Configuration Updates
```lua
-- Initial setup
require("terrareg").setup({ debug = false })

-- Update configuration later
require("terrareg").setup({ debug = true })

-- Configuration is merged, not replaced
local config = require("terrareg").get_config()
-- config.debug is now true, other options remain unchanged
```

## Type Definitions

```lua
---@class TerraregConfig
---@field option1 boolean Primary feature toggle
---@field option2 string Operational mode
---@field debug boolean Debug mode toggle

---@class TerraregModule
---@field config TerraregConfig Current configuration
---@field setup fun(opts?: TerraregConfig): nil Initialize terrareg
---@field get_config fun(): TerraregConfig Get current configuration
```

## Error Handling

### Configuration Validation

terrareg validates configuration on setup:

```lua
-- This will raise an error for invalid types
require("terrareg").setup({
  option1 = "not_a_boolean",  -- Error: expected boolean
})
```

### Safe Configuration Access

```lua
-- Safe way to check configuration
local ok, config = pcall(require("terrareg").get_config)
if ok then
  print("Debug mode:", config.debug)
else
  print("terrareg not initialized")
end
```

## Advanced Usage

### Programmatic Configuration

```lua
-- Function to create environment-specific config
local function create_config(env)
  local base_config = {
    option1 = true,
    option2 = "default",
    debug = false,
  }

  if env == "development" then
    base_config.debug = true
    base_config.option2 = "dev"
  elseif env == "testing" then
    base_config.option1 = false
    base_config.debug = true
  end

  return base_config
end

-- Use environment-specific configuration
local env = vim.env.NODE_ENV or "production"
require("terrareg").setup(create_config(env))
```

### Configuration Hooks

```lua
-- Setup with post-configuration callback
require("terrareg").setup({
  option1 = true,
  debug = true,
})

-- Verify setup completed
local config = require("terrareg").get_config()
if config.debug then
  print("terrareg initialized with debug mode")
end
```

## Best Practices

1. **Always call setup()**: Even if using defaults
2. **Validate configuration**: Check config after setup in debug mode
3. **Use type annotations**: For better IDE support
4. **Handle errors gracefully**: Wrap API calls in pcall when appropriate
5. **Document custom configurations**: Make your setup clear for others

## Migration Guide

### From Version 1.x to 2.x

```lua
-- Old way (v1.x)
require("terrareg").init({
  enable = true,
  mode = "default",
})

-- New way (v2.x)
require("terrareg").setup({
  option1 = true,
  option2 = "default",
})
```

::: tip API Stability
The core API (`setup` and `get_config`) is stable and follows semantic versioning. Breaking changes will only occur in major version releases.
:::
