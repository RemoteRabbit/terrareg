# terrareg

A Neovim plugin for [brief description of what the plugin does].

## Installation

### Stable Release

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

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

#### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

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

### Beta Testing

To help test new features before they're released:

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "remoterabbit/terrareg",
  branch = "beta", -- Use beta branch for testing
  config = function()
    require("terrareg").setup({
      -- your configuration here
    })
  end,
}
```

#### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "remoterabbit/terrareg",
  branch = "beta", -- Use beta branch for testing
  config = function()
    require("terrareg").setup({
      -- your configuration here
    })
  end
}
```

⚠️ **Beta versions may contain bugs and breaking changes. Use at your own risk.**

## Configuration

```lua
require("terrareg").setup({
  -- Default configuration options will go here
})
```

## Usage

[Add usage instructions here]

## Contributing

1. Install [pre-commit](https://pre-commit.com/)
2. Run `pre-commit install` to set up the git hook scripts
3. Make your changes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.
