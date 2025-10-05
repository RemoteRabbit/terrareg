# Quick Start

Get up and running with terrareg in just a few minutes.

## Basic Setup

After [installing](/guide/installation) terrareg, add this to your Neovim configuration:

```lua
require("terrareg").setup()
```

This will initialize terrareg with default settings.

## First Steps

### 1. Verify Installation

Check that terrareg is working correctly:

```lua
:lua print(vim.inspect(require("terrareg").get_config()))
```

You should see the default configuration printed.

### 2. Basic Configuration

Customize terrareg to your preferences:

```lua
require("terrareg").setup({
  option1 = false,        -- Disable option1
  option2 = "my_value",   -- Custom string value
  debug = true,           -- Enable debug mode for troubleshooting
})
```

### 3. Test Basic Functionality

Try these basic operations:

```vim
" Example commands (if available)
:TerraregStatus
:TerraregInfo
```

## Common Use Cases

### Development Workflow

Here's how terrareg fits into a typical development workflow:

1. **Project Setup**: Configure terrareg for your project type
2. **Daily Usage**: Use the main features for your development tasks
3. **Customization**: Adjust settings as your needs evolve

### Integration with Other Plugins

terrareg works well with popular Neovim plugins:

```lua
-- Example integration setup
require("terrareg").setup({
  -- Configuration that works well with other plugins
  option1 = true,
  option2 = "compatible_mode",
})
```

## Key Bindings

While terrareg doesn't set any default key bindings, here are some recommended mappings:

```lua
-- Add to your key mapping configuration
vim.keymap.set('n', '<leader>tr', function()
  -- Toggle terrareg feature
  print("Terrareg feature toggled")
end, { desc = 'Toggle Terrareg' })

vim.keymap.set('n', '<leader>ti', function()
  -- Show terrareg info
  print(vim.inspect(require("terrareg").get_config()))
end, { desc = 'Terrareg Info' })
```

## Configuration Examples

### Minimal Setup
```lua
require("terrareg").setup()
```

### Custom Setup
```lua
require("terrareg").setup({
  option1 = false,
  option2 = "production",
  debug = false,
})
```

### Development Setup
```lua
require("terrareg").setup({
  option1 = true,
  option2 = "development",
  debug = true,
})
```

## Next Steps

Now that you have the basics working:

1. 📖 Read the [Configuration Guide](/guide/configuration) for detailed options
2. 🔧 Explore [Advanced Features](/guide/advanced) for power-user capabilities
3. 📚 Check the [API Documentation](/api/) for programmatic usage
4. 💡 Browse [Examples](/examples/) for real-world use cases

## Troubleshooting

If something isn't working:

### Check Configuration
```lua
-- Verify your configuration is valid
:lua print(vim.inspect(require("terrareg").get_config()))
```

### Enable Debug Mode
```lua
require("terrareg").setup({
  debug = true,  -- This will show helpful debug information
})
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Plugin not loading | Check plugin manager configuration |
| Configuration errors | Verify Lua syntax in setup call |
| Unexpected behavior | Enable debug mode and check messages |

::: tip Pro Tip
Start with the default configuration and gradually customize it as you learn what works best for your workflow.
:::

::: warning Important
Make sure to restart Neovim after making configuration changes for them to take effect.
:::
