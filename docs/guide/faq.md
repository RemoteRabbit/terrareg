# Frequently Asked Questions (FAQ)

Common questions and answers about terrareg.

## General Questions

### What is terrareg?

terrareg is a Neovim plugin designed to enhance your development workflow with powerful features and integrations.

### What are the system requirements?

- **Neovim**: Version 0.7.0 or later (0.9.0+ recommended)
- **Lua**: Version 5.1 or later
- **Operating System**: Linux, macOS, or Windows

### Is terrareg compatible with other plugins?

Yes! terrareg is designed to work well with popular Neovim plugins including:
- LSP configurations (nvim-lspconfig, mason.nvim)
- Completion engines (nvim-cmp, coq_nvim)
- File explorers (nvim-tree, neo-tree)
- Fuzzy finders (telescope.nvim, fzf-lua)

## Installation Issues

### Q: Plugin manager can't find terrareg

**A:** Make sure you're using the correct repository URL:
```lua
"remoterabbit/terrareg"  -- Correct
```

### Q: Getting "module not found" errors

**A:** This usually indicates an installation issue:

1. Verify the plugin is installed: `:Lazy` (for lazy.nvim) or equivalent
2. Check for error messages: `:messages`
3. Restart Neovim completely
4. Try reinstalling the plugin

### Q: Plugin loads but setup() fails

**A:** Check your configuration syntax:

```lua
-- ✅ Correct
require("terrareg").setup({
  option1 = true,
  option2 = "value"
})

-- ❌ Common mistakes
require("terrareg").setup(
  option1 = true,  -- Missing braces
  option2 = "value"
)
```

## Configuration Problems

### Q: Configuration changes don't take effect

**A:** Make sure to:
1. Restart Neovim after config changes
2. Check for syntax errors in your config
3. Verify the configuration location (init.lua vs plugin config)

### Q: How do I reset to default configuration?

**A:** Simply call setup without arguments:
```lua
require("terrareg").setup()  -- Uses all defaults
```

### Q: Can I have different configs for different projects?

**A:** Yes! Use project-local configuration:

```lua
-- In your global config
require("terrareg").setup({
  project_config = {
    enabled = true,
    config_file = ".terrareg.lua"  -- Look for project config
  }
})
```

## Performance Issues

### Q: Neovim starts slowly after installing terrareg

**A:** Use lazy loading to improve startup time:

```lua
{
  "remoterabbit/terrareg",
  event = "VimEnter",        -- Load after startup
  cmd = { "TerraregToggle" }, -- Load on command
  ft = { "lua" },            -- Load for specific file types
}
```

### Q: Memory usage seems high

**A:** Configure memory limits:

```lua
require("terrareg").setup({
  cache_size = 100,          -- Reduce cache size
  cleanup_interval = 60,     -- More frequent cleanup
  memory_limit = "50MB"      -- Set memory limit
})
```

### Q: Operations feel slow

**A:** Enable performance optimizations:

```lua
require("terrareg").setup({
  performance = {
    async_operations = true,   -- Use async when possible
    batch_size = 50,          -- Process in batches
    debounce_delay = 100      -- Reduce update frequency
  }
})
```

## Feature Questions

### Q: How do I enable debug mode?

**A:** Add debug configuration:

```lua
require("terrareg").setup({
  debug = true,  -- Simple debug mode
  -- OR
  debug = {
    enabled = true,
    level = "info",           -- trace, debug, info, warn, error
    output = "console"        -- console, file, both
  }
})
```

### Q: Can I customize key bindings?

**A:** terrareg doesn't set default bindings. Add your own:

```lua
vim.keymap.set('n', '<leader>tt', function()
  require("terrareg").toggle()
end, { desc = 'Toggle Terrareg' })

vim.keymap.set('n', '<leader>ti', function()
  print(vim.inspect(require("terrareg").get_info()))
end, { desc = 'Terrareg Info' })
```

### Q: How do I integrate with my statusline?

**A:** Use the status API:

```lua
-- For lualine
require('lualine').setup({
  sections = {
    lualine_x = {
      function()
        return require("terrareg").get_status()
      end
    }
  }
})
```

## Troubleshooting

### Q: How do I report bugs?

**A:** Follow these steps:

1. Enable debug mode to gather information
2. Check existing [issues](https://github.com/RemoteRabbit/terrareg/issues)
3. Create a [new issue](https://github.com/RemoteRabbit/terrareg/issues/new) with:
   - Neovim version (`:version`)
   - terrareg version
   - Minimal config to reproduce
   - Error messages/logs

### Q: Commands not working as expected

**A:** Verify the commands exist:

```lua
-- Check available commands
:lua print(vim.inspect(require("terrareg").get_commands()))
```

### Q: Integration with other plugins broken

**A:** Common integration issues:

1. **Load order**: Ensure terrareg loads after dependencies
2. **Key conflicts**: Check for conflicting key mappings
3. **API changes**: Update other plugins if using terrareg APIs

## Advanced Usage

### Q: Can I extend terrareg with custom functions?

**A:** Yes! Create custom extensions:

```lua
-- Register custom function
require("terrareg").register_function("my_function", function(args)
  -- Your custom logic
  print("Custom function called with:", vim.inspect(args))
end)

-- Use it
require("terrareg").call_function("my_function", { data = "test" })
```

### Q: How do I contribute to terrareg?

**A:** We welcome contributions!

1. Read the [Contributing Guide](https://github.com/RemoteRabbit/terrareg/blob/main/CONTRIBUTING.md)
2. Check the [good first issues](https://github.com/RemoteRabbit/terrareg/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
3. Join our [discussions](https://github.com/RemoteRabbit/terrareg/discussions)

### Q: Where can I find more examples?

**A:** Check out:
- [Examples directory](https://github.com/RemoteRabbit/terrareg/tree/main/examples)
- [Wiki](https://github.com/RemoteRabbit/terrareg/wiki)
- [Community configurations](https://github.com/RemoteRabbit/terrareg/discussions/categories/show-and-tell)

## Still Need Help?

If your question isn't answered here:

1. 💬 [Start a discussion](https://github.com/RemoteRabbit/terrareg/discussions)
2. 🐛 [Report a bug](https://github.com/RemoteRabbit/terrareg/issues/new?template=bug_report.md)
3. 💡 [Request a feature](https://github.com/RemoteRabbit/terrareg/issues/new?template=feature_request.md)
4. 📖 Check the [full documentation](/)

We're here to help! 🚀
