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
style = true
template = true
merge = true

-- Custom CSS for better styling
custom_css = [[
body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
.function_list { background: #f8f9fa; padding: 10px; border-radius: 5px; }
pre { background: #f6f8fa; padding: 15px; border-radius: 6px; border: 1px solid #d0d7de; }
]]

-- Aliases for common patterns
alias("tparam", {"param", "type"})
alias("treturn", {"return", "type"})

-- Custom tags
new_type("config", "Configuration")
new_type("command", "Commands")
new_type("autocmd", "Autocommands")
