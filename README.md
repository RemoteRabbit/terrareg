# terrareg.nvim

A Neovim plugin for managing Terraform provider documentation locally. Download, index, and browse official Terraform provider docs with powerful picker integration.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
- [Commands](#commands)
- [API](#api)
- [Contributing](#contributing)
- [License](#license)

## Features

- 📦 **Local Documentation**: Download and manage Terraform provider docs locally
- 🔍 **Powerful Pickers**: Browse providers and docs with Snacks.nvim integration
- 🚀 **Fast Access**: Instantly search through indexed documentation
- 📊 **Version Management**: Keep track of multiple provider versions (last 3)
- 🔄 **Auto-updates**: Automatically update to latest provider versions
- 🌐 **Official Sources**: Downloads directly from HashiCorp's GitHub repositories
- 💾 **Persistent Storage**: Local caching for offline access

## Requirements

- Neovim 0.8+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required dependency)
- [Snacks.nvim](https://github.com/folke/snacks.nvim) (optional, for picker integration)
- `git` (for downloading provider documentation)
- `curl` (for API requests)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "RemoteRabbit/terrareg",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required
    "folke/snacks.nvim",     -- Optional (for pickers)
  },
  config = function()
    require("terrareg").setup({
      -- your configuration here (see Setup section)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "RemoteRabbit/terrareg",
  requires = {
    "nvim-lua/plenary.nvim", -- Required
    "folke/snacks.nvim",     -- Optional (for pickers)
  },
  config = function()
    require("terrareg").setup({
      -- your configuration here (see Setup section)
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'  " Required
Plug 'folke/snacks.nvim'      " Optional (for pickers)
Plug 'RemoteRabbit/terrareg'

" In your init.lua or init.vim:
lua require('terrareg').setup({})
```

## Setup

Call `setup()` to configure the plugin. Here are the available options:

```lua
require("terrareg").setup({
  -- Directory path for storing terrareg data (default: vim.fn.stdpath("data") .. "/terrareg")
  dir_path = vim.fn.stdpath("data") .. "/terrareg",
  
  -- How to open documentation windows (default: "float")
  open_mode = "float", -- "split", "float", etc.
  
  -- Floating window configuration (when open_mode = "float")
  float_win = {
    relative = "editor",
    height = "30",
    width = "120",
    border = "rounded",
  },
  
  -- List of providers to ensure are installed on startup (default: {})
  ensure_installed = { "aws", "kubernetes", "helm" },
  
  -- Picker configuration (requires Snacks.nvim)
  pickers = {
    enabled = true, -- Enable picker functionality
    docs_open_cmd = "float", -- How to open docs: "float", "edit", "vsplit", "split", "tabnew"
    keep_float_buffers = false, -- Keep floating window buffers after closing
  },
})
```

### First Time Setup

1. **Build the provider registry** (required first step):

   ```vim
   :TerraregBuildReg
   ```

2. **Install providers** you want to use:

   ```vim
   :TerraregInstall aws
   :TerraregInstall kubernetes
   :TerraregInstall helm
   ```

3. **Browse available providers** with picker (if Snacks.nvim is installed):

   ```vim
   :TerraregPickerAvailable
   ```

## Usage

The plugin provides both command-line and programmatic interfaces for managing Terraform provider documentation.

### Basic Workflow

1. **Build the provider registry**: `TerraregBuildReg`
2. **Install providers**: `TerraregInstall <provider>`  
3. **Browse with pickers**: `TerraregPickerInstalled` or `TerraregPickerAvailable`
4. **Update providers**: `TerraregUpdate [provider]`

## Commands

| Command | Description |
|---------|-------------|
| `:TerraregBuildReg` | Build the local provider registry from GitHub API |
| `:TerraregInstall <provider>` | Install a specific provider (e.g., `aws`, `kubernetes`) |
| `:TerraregUpdate [provider]` | Update provider(s) to latest versions. No args = update all |
| `:TerraregRemove <provider>` | Remove a provider and its documentation |
| `:TerraregPickerInstalled` | Open picker for installed providers (requires Snacks.nvim) |
| `:TerraregPickerAvailable` | Open picker for available providers (requires Snacks.nvim) |
| `:TerraregPickerDocs` | Open picker for provider documentation (requires Snacks.nvim) |
| `:TerraregPickerDocBuffers` | Open picker for documentation buffers (requires Snacks.nvim) |

### Examples

```lua
-- Setup the plugin
require("terrareg").setup({
  ensure_installed = { "aws", "kubernetes" },
})

-- Programmatic access to pickers (if available)
require('terrareg').pick_installed_providers()
require('terrareg').pick_available_providers()
require('terrareg').pick_provider_docs()
require('terrareg').pick_doc_buffers()
```

## API

### Main Functions

```lua
local terrareg = require('terrareg')

-- Setup the plugin (required)
terrareg.setup({
  ensure_installed = { "aws", "kubernetes" },
  pickers = { enabled = true }
})

-- Picker functions (requires Snacks.nvim)
terrareg.pick_installed_providers(opts)
terrareg.pick_available_providers(opts)
terrareg.pick_provider_docs(opts)
terrareg.pick_doc_buffers(opts)
```

### Data Storage

The plugin stores all data in `vim.fn.stdpath("data") .. "/terrareg/"`:

```
~/.local/share/nvim/terrareg/
├── docs/                    # Downloaded provider documentation
│   ├── aws/
│   │   ├── v6.16.0/        # Provider version directories
│   │   ├── v6.15.0/
│   │   ├── v6.14.1/
│   │   └── index.json      # Generated resource index
│   └── kubernetes/
├── registry.json           # Provider registry cache
└── lock.json              # Installed provider tracking
```

## Contributing

Contributions are welcome! Here's how you can help:

### Development Setup

1. Fork and clone the repository
2. Install development dependencies:
   - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
   - [Snacks.nvim](https://github.com/folke/snacks.nvim) (optional)
3. Make your changes
4. Test your changes thoroughly
5. Submit a pull request

### Areas for Contribution

- **Bug fixes** and performance improvements
- **Documentation** improvements and examples  
- **New features** like additional picker integrations
- **Testing** and quality assurance
- **Provider-specific enhancements**

Please open an issue first to discuss major changes.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
