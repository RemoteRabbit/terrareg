# Installation

terrareg can be installed using any popular Neovim plugin manager. Choose the method that matches your setup.

## Plugin Managers

### lazy.nvim (Recommended)

[lazy.nvim](https://github.com/folke/lazy.nvim) is the modern, fast plugin manager for Neovim.

```lua
{
  "remoterabbit/terrareg",
  config = function()
    require("terrareg").setup({
      -- your configuration here
    })
  end,
}
```

#### With Custom Configuration

```lua
{
  "remoterabbit/terrareg",
  opts = {
    option1 = false,
    option2 = "custom_value",
    debug = false,
  },
}
```

#### Lazy Loading (Optional)

```lua
{
  "remoterabbit/terrareg",
  cmd = { "TerraregCommand" }, -- Load only when command is used
  ft = { "lua", "vim" },       -- Load only for specific file types
  keys = {
    { "<leader>tr", "<cmd>TerraregToggle<cr>", desc = "Toggle Terrareg" },
  },
  config = function()
    require("terrareg").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "remoterabbit/terrareg",
  config = function()
    require("terrareg").setup({
      -- your configuration here
    })
  end
}
```

### vim-plug

```vim
Plug 'remoterabbit/terrareg'
```

Then add to your `init.lua`:

```lua
require("terrareg").setup({
  -- your configuration here
})
```

### dein.vim

```vim
call dein#add('remoterabbit/terrareg')
```

## Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/RemoteRabbit/terrareg.git ~/.local/share/nvim/site/pack/plugins/start/terrareg
   ```

2. Add to your Neovim configuration:
   ```lua
   require("terrareg").setup()
   ```

## Verification

After installation, verify that terrareg is working:

1. Restart Neovim
2. Run `:lua print("terrareg loaded:", require("terrareg") ~= nil)`
3. You should see: `terrareg loaded: true`

## Updating

### lazy.nvim
```vim
:Lazy update terrareg
```

### packer.nvim
```vim
:PackerUpdate terrareg
```

### Manual
```bash
cd ~/.local/share/nvim/site/pack/plugins/start/terrareg
git pull
```

## Troubleshooting

### Common Issues

#### Plugin Not Loading
- Ensure your plugin manager is properly configured
- Check for error messages with `:messages`
- Verify Neovim version compatibility

#### Configuration Errors
- Check your configuration syntax
- Use `:checkhealth terrareg` (if available)
- Enable debug mode: `require("terrareg").setup({ debug = true })`

### Getting Help

If you encounter issues:

1. Check the [FAQ](/guide/faq)
2. Search [existing issues](https://github.com/RemoteRabbit/terrareg/issues)
3. Join our [discussions](https://github.com/RemoteRabbit/terrareg/discussions)
4. Create a [new issue](https://github.com/RemoteRabbit/terrareg/issues/new)

::: tip Next Steps
Now that you have terrareg installed, continue to the [Quick Start](/guide/quick-start) guide to learn the basics.
:::
