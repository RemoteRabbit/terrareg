# terrareg Documentation

Modern VitePress-powered documentation site with beautiful design, fast performance, and excellent developer experience.

## Quick Start

### View Online Documentation
**🌐 [Visit the Documentation Site](https://remoterabbit.github.io/terrareg/)**

### Develop Documentation Locally

```bash
# Install dependencies
make docs-install

# Start development server (hot reload)
make docs-dev
# Opens http://localhost:5173

# Build production version
make docs

# Serve production build locally
make docs-serve
# Opens http://localhost:4173
```

## Documentation Structure

```
docs/
├── .vitepress/          # VitePress configuration
├── index.md            # Landing page
├── guide/              # User guides
│   ├── installation.md
│   ├── quick-start.md
│   └── configuration.md
├── api/                # API reference
└── examples/           # Real-world examples
```

## Contributing to Documentation

### Adding Content

1. **Guides**: Add new `.md` files in `guide/`
2. **API Docs**: Update `api/` directory
3. **Examples**: Add to `examples/`

### Local Development

```bash
# Start development server with hot reload
make docs-dev
```

### Configuration

Edit `.vitepress/config.js` to:
- Add new navigation items
- Configure sidebar
- Update site metadata

### Writing Documentation

Use standard Markdown with VitePress enhancements:

```markdown
::: tip Pro Tip
This is a helpful tip!
:::

::: warning Important
This is important information.
:::

::: danger Caution
This requires careful attention.
:::
```

### Code Examples

```lua
-- Syntax highlighting works automatically
require("terrareg").setup({
  option1 = true,
  option2 = "custom",
})
```

## Deployment

Documentation is automatically deployed via GitHub Actions:
- **Trigger**: Push to `main` branch with changes in `docs/`
- **Output**: https://remoterabbit.github.io/terrareg/
- **Build**: VitePress static site generation

## Features

- 🚀 **Fast**: Built with Vite for lightning-fast development
- 📱 **Responsive**: Mobile-friendly design
- 🔍 **Searchable**: Built-in search functionality
- 🎨 **Beautiful**: Modern, clean design
- ⚡ **Hot Reload**: Instant updates during development
- 📊 **Analytics Ready**: Easy to integrate with analytics
