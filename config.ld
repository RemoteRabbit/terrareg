title = "terrareg"
description = "A Neovim plugin for [brief description]"
project = "terrareg"
dir = "docs/generated"

-- Source directories
file = {
  "lua/terrareg",
  "plugin",
}

-- Format
format = "markdown"
output = "."
all = true
merge = true

-- Custom CSS would go here if needed

-- Aliases for common patterns
alias("tparam", {"param", "type"})
alias("treturn", {"return", "type"})

-- Custom tags
new_type("config", "Configuration")
new_type("command", "Commands")
new_type("autocmd", "Autocommands")
