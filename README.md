# terrareg.nvim

A Neovim plugin for browsing and inserting Terraform AWS provider documentation with Telescope integration.

## Features

- 🔍 **Telescope Integration**: Browse AWS resources and data sources with fuzzy search
- 📖 **Rich Documentation Display**: View formatted documentation in floating windows
- 💡 **Example Code Insertion**: Insert Terraform examples directly into your buffer
- 🚀 **Fast Access**: Quickly find and reference AWS resources while coding
- 📊 **Comprehensive Coverage**: Includes common AWS resources and data sources
- 🌐 **Multiple Sources**: Fetches from Terraform Registry with GitHub fallback

## Installation

### Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- `curl` (for HTTP requests)

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

The plugin comes with the following default configuration:

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
})
```

## Usage

### Commands

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
-- Open AWS resources picker
require('terrareg').aws_resources()

-- Search for S3 resources
require('terrareg').search('s3')

-- Show documentation for aws_s3_bucket
require('terrareg').show_docs('resource', 'aws_s3_bucket')

-- Insert example code for aws_instance
require('terrareg').insert_example('resource', 'aws_instance')
```

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

The plugin includes documentation for common AWS resources including:

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

1. Install [pre-commit](https://pre-commit.com/)
2. Run `pre-commit install` to set up the git hook scripts
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
