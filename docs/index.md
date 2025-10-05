---
layout: home

hero:
  name: "terrareg"
  text: "Modern Neovim Plugin"
  tagline: "Enhance your development workflow with powerful features"
  image:
    src: /logo.svg
    alt: terrareg
  actions:
    - theme: brand
      text: Get Started
      link: /guide/
    - theme: alt
      text: View on GitHub
      link: https://github.com/RemoteRabbit/terrareg

features:
  - icon: ⚡
    title: Lightning Fast
    details: Built with performance in mind, terrareg provides instant responsiveness without slowing down your editor.

  - icon: 🛠️
    title: Highly Configurable
    details: Customize every aspect of the plugin to fit your workflow with comprehensive configuration options.

  - icon: 🔧
    title: Developer Friendly
    details: Clean API design and extensive documentation make it easy to extend and integrate with your setup.

  - icon: 🎨
    title: Modern UI
    details: Beautiful, intuitive interface that integrates seamlessly with your Neovim theme.

  - icon: 📦
    title: Zero Dependencies
    details: Works out of the box with no external dependencies - just install and go.

  - icon: 🔄
    title: Active Development
    details: Regularly updated with new features, improvements, and bug fixes.
---

## Quick Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

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

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

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

## Why terrareg?

terrareg is designed to enhance your Neovim experience with modern development practices in mind. Whether you're a seasoned developer or just getting started with Neovim, terrareg provides the tools you need to be productive.

::: tip Getting Help
Check out our [GitHub Discussions](https://github.com/RemoteRabbit/terrareg/discussions) for community support, or [open an issue](https://github.com/RemoteRabbit/terrareg/issues) if you find a bug.
:::
