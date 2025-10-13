# terrareg.nvim

An extensible Neovim plugin for browsing and inserting Terraform provider documentation (AWS, Azure, GCP, and more) with Telescope integration.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API](#api)
- [Supported Resources](#supported-resources)
- [Extending & Contributing](#extending--contributing)
- [Getting Help](#getting-help)
- [License](#license)
## Features

- 🔍 **Telescope Integration**: Browse Terraform resources and data sources with fuzzy search
- 📖 **Rich Documentation Display**: View formatted documentation in floating windows
- 💡 **Example Code Insertion**: Insert Terraform examples directly into your buffer
- 🚀 **Fast Access**: Quickly find and reference resources while coding
- 📊 **Comprehensive Coverage**: Includes common AWS, Azure, GCP, and other resources
- 🌐 **Multiple Sources**: Fetches from Terraform Registry with GitHub fallback
- 🧩 **Extensible Providers**: Easily add support for new cloud providers

## Installation

### Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- `curl` (for HTTP requests)
- Neovim 0.8+

### Stable Release

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "remoterabbit/terrareg",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
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
  requires = {
    "nvim-telescope/telescope.nvim",
  },
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
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
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
  requires = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("terrareg").setup({
      -- your configuration here
    })
  end
}
```

⚠️ **Beta versions may contain bugs and breaking changes. Use at your own risk.**

## Configuration

The plugin comes with the following default configuration (see [docs/guide/configuration.md](docs/guide/configuration.md) for all options):

```lua
require("terrareg").setup({
  -- Display options
  display_mode = "float", -- "float", "popup", or "split"

  -- Window options
  window = {
    width = 80,
    height = 30,
    border = "rounded",
  },

  -- HTTP options
  timeout = 30000, -- 30 seconds

  -- Debug mode
  debug = false,

  -- List of providers to use (tries in order)
  providers = {"aws", "azure", "gcp"},
})
```

## Usage

### Commands ([Full usage guide](docs/guide/quick-start.md))

| Command | Description |
|---------|-------------|
| `:TerraregResources [query]` | Open picker for all AWS resources and data sources |
| `:TerraregResourcesOnly [query]` | Open picker for AWS resources only |
| `:TerraregDataSources [query]` | Open picker for AWS data sources only |
| `:TerraregSearch [query]` | Search AWS resources (prompts if no query provided) |
| `:TerraregDocs <type> <name>` | Show documentation for specific resource |
| `:TerraregInsert <type> <name>` | Insert example code at cursor |

### Telescope Extension

After installation, you can also use the Telescope extension:

```
:Telescope terrareg aws_resources
:Telescope terrareg resources
:Telescope terrareg data_sources
```

### Key Mappings in Documentation Window

- `q` or `<Esc>` - Close documentation window
- `o` - Open documentation URL in browser

### Examples

```lua
require('terrareg').aws_resources()

require('terrareg').search('s3')

require('terrareg').show_docs('resource', 'aws_s3_bucket')

require('terrareg').insert_example('resource', 'aws_instance')
```

See [API documentation](docs/api/index.md) for all available functions.

## API

### Main Functions

```lua
local terrareg = require('terrareg')

-- Setup the plugin
terrareg.setup(opts)

-- Open AWS resources picker
terrareg.aws_resources(opts)

-- Open resources only picker
terrareg.aws_resources_only(opts)

-- Open data sources picker
terrareg.aws_data_sources(opts)

-- Search resources
terrareg.search(query, opts)

-- Show documentation
terrareg.show_docs(resource_type, resource_name)

-- Get documentation data
terrareg.get_docs(resource_type, resource_name, callback)

-- Insert example code
terrareg.insert_example(resource_type, resource_name)
```

### Resource Types

- `"resource"` - Terraform resources (e.g., `aws_s3_bucket`)
- `"data"` - Terraform data sources (e.g., `aws_ami`)

## Supported Resources

The plugin includes documentation for common AWS, Azure, GCP, and other resources including:

- **Compute**: EC2 instances, Auto Scaling Groups, Launch Templates
- **Storage**: S3 buckets, EBS volumes
- **Database**: RDS instances, DynamoDB tables
- **Networking**: VPCs, subnets, security groups, load balancers
- **IAM**: Roles, policies, users, groups
- **Lambda**: Functions, permissions, aliases
- **CloudWatch**: Log groups, metric alarms

## Enhanced Table Format

The plugin displays arguments in a comprehensive 4-column table:

```
┌──────────────────────────────┬──────────────┬──────────────────┬────────────────────────────────────────────────────────────┐
│ Argument Name                │ Required     │ Default          │ Description                                                │
├──────────────────────────────┼──────────────┼──────────────────┼────────────────────────────────────────────────────────────┤
│ bucket (!)                   │   Opt        │                  │ Name of the bucket. If omitted, Terraform will assign a   │
│                              │              │                  │ random, unique name.                                      │
│ force_destroy                │   Opt        │ false            │ Boolean that indicates all objects should be deleted from │
│                              │              │                  │ the bucket when the bucket is destroyed.                  │
│ vpc_id                       │ * Req        │                  │ VPC ID where the bucket will be created.                  │
│ tags                         │   Opt        │ {}               │ Map of tags to assign to the bucket resource.             │
└──────────────────────────────┴──────────────┴──────────────────┴────────────────────────────────────────────────────────────┘

Legend: * Req = Required, Opt = Optional, (!) = Forces new resource
```

### Features:
- **Smart Parsing**: Automatically extracts required/optional status and default values
- **Visual Indicators**: Clear symbols (* for required, (!) for forces new resource)
- **Force New Warning**: (!) symbol indicates arguments that force resource recreation
- **Default Values**: Shows default values when specified in documentation
- **Text Wrapping**: Long descriptions wrap properly within table cells
- **Unicode-Safe**: Compatible formatting that works across different terminal types

## Contributing


### Extending Providers

To add support for a new cloud provider:
1. Create a new Lua module in `lua/terrareg/providers/` (see [docs/guide/advanced.md](docs/guide/advanced.md)).
2. Implement required functions (`list_resources`, `get_docs`, etc.).
3. Add tests in `tests/test_providers.lua`.
4. Update documentation in `docs/api/index.md` and `docs/guide/advanced.md`.
5. Submit a pull request.

### Contributor Guide
1. Install [pre-commit](https://pre-commit.com/)
2. Run `pre-commit install` to set up the git hook scripts
3. Make your changes
4. Submit a pull request

## Getting Help

- [FAQ](docs/guide/faq.md)
- [Configuration Guide](docs/guide/configuration.md)
- [API Reference](docs/api/index.md)
- [Open an Issue](https://github.com/RemoteRabbit/terrareg/issues)
## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
