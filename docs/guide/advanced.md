# Advanced Features

This guide covers advanced usage patterns and features for power users.

## Advanced Configuration

### Custom Handlers

You can define custom handlers for specialized workflows:

```lua
require("terrareg").setup({
  custom_handlers = {
    special_handler = function(context)
      -- Custom logic here
      print("Custom handler executed")
    end
  }
})
```

### Environment-Specific Configuration

Configure terrareg differently based on your environment:

```lua
local config = {
  option1 = true,
  option2 = "default"
}

-- Development environment
if vim.env.TERRAREG_ENV == "development" then
  config.debug = true
  config.option2 = "dev_mode"
end

-- Production environment
if vim.env.TERRAREG_ENV == "production" then
  config.debug = false
  config.option2 = "prod_mode"
end

require("terrareg").setup(config)
```

## Performance Optimization


### Cache Tuning

terrareg uses a smart cache for documentation and resource data. You can tune cache settings for performance:

```lua
require("terrareg.cache").setup({
  ttl = 7200,         -- Time to live in seconds (default: 3600)
  max_entries = 2000, -- Maximum cache entries (default: 1000)
})
```

**Tips:**
- Use a higher `max_entries` for large projects or frequent lookups.
- Lower `ttl` for more up-to-date data, higher for speed.
- Use `require("terrareg.cache").get_stats()` to monitor cache hit rates.
- Call `require("terrareg.cache").preload_popular()` to warm up cache for common resources.

### Lazy Loading

Optimize startup time by configuring lazy loading:

```lua
{
  "remoterabbit/terrareg",
  event = "VimEnter",  -- Load after Vim starts
  cmd = {              -- Load on these commands
    "TerraregToggle",
    "TerraregStatus"
  },
  ft = { "lua" },      -- Load for specific file types
}
```

### Memory Management

Configure memory usage for large projects:

```lua
require("terrareg").setup({
  cache_size = 1000,      -- Limit cache entries
  cleanup_interval = 300, -- Cleanup every 5 minutes
  memory_limit = "100MB"  -- Memory usage limit
})
```

## Integration Patterns

### LSP Integration

Integrate with Language Server Protocol:

```lua
require("terrareg").setup({
  lsp_integration = {
    enabled = true,
    servers = { "lua_ls", "pyright" },
    on_attach = function(client, bufnr)
      -- Custom LSP setup
    end
  }
})
```

### Telescope Integration

Use with Telescope for enhanced search:

```lua
-- Add to your telescope config
require("telescope").setup({
  extensions = {
    terrareg = {
      search_depth = 3,
      show_hidden = false
    }
  }
})

require("telescope").load_extension("terrareg")
```

## Advanced API Usage

### Programmatic Control

Control terrareg programmatically:

```lua
local terrareg = require("terrareg")

-- Get current state
local state = terrareg.get_state()

-- Batch operations
terrareg.batch_update({
  operation1 = { type = "update", data = {} },
  operation2 = { type = "delete", id = "item1" }
})

-- Event handling
terrareg.on("state_changed", function(new_state)
  print("State updated:", vim.inspect(new_state))
end)
```

### Custom Extensions

Create custom extensions:

```lua
-- In lua/terrareg/extensions/my_extension.lua
local M = {}

function M.setup(opts)
  -- Extension setup
end

function M.execute(args)
  -- Extension logic
end

return M
```

Register the extension:

```lua
require("terrareg").register_extension("my_extension", {
  path = "terrareg.extensions.my_extension",
  config = { option1 = true }
})
```

## Debugging and Profiling

### Debug Mode

Enable comprehensive debugging:

```lua
require("terrareg").setup({
  debug = {
    enabled = true,
    level = "trace",      -- trace, debug, info, warn, error
    output = "file",      -- console, file, both
    file_path = "~/.terrareg.log"
  }
})
```

### Performance Profiling

Profile performance bottlenecks:

```lua
-- Enable profiling
require("terrareg").enable_profiling()

-- Run operations
-- ... your workflow ...

-- Get profiling results
local profile = require("terrareg").get_profile_results()
print(vim.inspect(profile))
```

## Error Handling

### Custom Error Handlers

Define custom error handling:

```lua
require("terrareg").setup({
  error_handler = function(error, context)
    -- Log error
    print("Terrareg error:", error.message)

    -- Send to monitoring service
    if vim.env.MONITOR_ERRORS then
      -- Custom monitoring logic
    end

    -- Decide whether to continue
    return error.recoverable
  end
})
```

### Graceful Degradation

Configure fallback behavior:

```lua
require("terrareg").setup({
  fallback_mode = {
    enabled = true,
    on_failure = "continue",  -- continue, stop, retry
    retry_count = 3,
    retry_delay = 1000        -- milliseconds
  }
})
```

## Security Considerations


### Best Practices for Credentials

- **Never put secrets or tokens in URLs or configuration files.**
- Use environment variables for all credentials and sensitive data.
- Mask sensitive patterns (e.g., `password`, `token`, `key`, `secret`) in logs and error messages.
- Use OS-level secret management (e.g., `pass`, `gopass`, `aws-vault`) for cloud credentials.
- Always review error messages before sharing logs to ensure no secrets are exposed.
- Prefer encrypted storage for any persistent secrets.

Example:
```lua
-- Use environment variable for API token
local api_token = vim.env.TERRAREG_API_TOKEN
```

**Tip:** If you contribute code, always audit for accidental credential exposure before submitting PRs.

### Access Control

Implement access controls:

```lua
require("terrareg").setup({
  access_control = {
    enabled = true,
    rules = {
      { pattern = "admin/*", required_role = "admin" },
      { pattern = "user/*", required_role = "user" }
    }
  }
})
```

## Best Practices

### Configuration Management

- Use environment variables for sensitive settings
- Keep development and production configs separate
- Version control your configuration files
- Document custom configurations

### Performance Tips

- Use lazy loading for large projects
- Configure appropriate cache sizes
- Monitor memory usage in long sessions
- Profile regularly to identify bottlenecks

### Maintenance

- Update regularly to get latest features
- Review and clean up unused configurations
- Monitor logs for errors and warnings
- Test configurations in safe environments

## Migration Guide

### From Version 1.x to 2.x

```lua
-- Old configuration (v1.x)
require("terrareg").setup({
  old_option = true,
  deprecated_setting = "value"
})

-- New configuration (v2.x)
require("terrareg").setup({
  new_option = true,        -- replaces old_option
  modern_setting = "value"  -- replaces deprecated_setting
})
```

### Breaking Changes

See the [CHANGELOG](https://github.com/RemoteRabbit/terrareg/blob/main/CHANGELOG.md) for detailed migration instructions.

## Contributing

Want to add advanced features? Check out our [Contributing Guide](https://github.com/RemoteRabbit/terrareg/blob/main/CONTRIBUTING.md).

## Adding a New Provider

You can extend terrareg to support new Terraform providers (e.g., Azure, GCP, custom) by following these steps:

### 1. Create a Provider Module

Create a new file in `lua/terrareg/providers/` (e.g., `azure.lua`).

Implement the following required functions:

```lua
local M = {}

-- Return a list of supported resources
function M.get_resources()
  return {
    {
      name = "azure_storage_account",
      type = "resource",
      category = "Storage",
      description = "Manages an Azure Storage Account.",
      provider = "azure",
    },
    -- ... more resources ...
  }
end

-- Search resources by query
function M.search_resources(query)
  -- Implement fuzzy search logic
end

-- Fetch documentation for a resource
function M.fetch_documentation(resource_type, resource_name, opts, callback)
  -- Fetch and return documentation data
end

return M
```

### 2. Register the Provider

In `lua/terrareg/providers/init.lua`, register your provider:

```lua
local providers = {}
providers.azure = require("terrareg.providers.azure")
-- ... other providers ...
return providers
```

### 3. Add Tests

Add tests in `tests/test_providers.lua` to validate your provider's functions and resource data.

### 4. Update Documentation

- Add your provider to the API docs and guides.
- Document any special configuration or usage.

### 5. Submit a Pull Request

Follow the [Contributing Guide](https://github.com/RemoteRabbit/terrareg/blob/main/CONTRIBUTING.md) and open a PR.

**Tip:** See existing provider modules (e.g., `aws.lua`, `kubernetes.lua`) for reference implementations.
