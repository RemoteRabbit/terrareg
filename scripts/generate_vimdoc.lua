-- Generate vimdoc from LuaDoc annotations
-- This script creates Neovim help documentation

local M = {}

local function write_vimdoc()
  local lines = {}

  -- Header
  table.insert(lines, "*terrareg.txt*  A Neovim plugin for [brief description]")
  table.insert(lines, "")
  table.insert(lines, "Author: remoterabbit")
  table.insert(lines, "License: GPL-3.0")
  table.insert(lines, "")
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "CONTENTS                                                    *terrareg-contents*"
  )
  table.insert(lines, "")
  table.insert(lines, "1. Introduction ............................ |terrareg-introduction|")
  table.insert(lines, "2. Installation ............................ |terrareg-installation|")
  table.insert(lines, "3. Configuration ........................... |terrareg-configuration|")
  table.insert(lines, "4. Usage ................................... |terrareg-usage|")
  table.insert(lines, "5. API ..................................... |terrareg-api|")
  table.insert(lines, "6. License ................................. |terrareg-license|")
  table.insert(lines, "")
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "INTRODUCTION                                            *terrareg-introduction*"
  )
  table.insert(lines, "")
  table.insert(lines, "terrareg.nvim is a Neovim plugin for [brief description].")
  table.insert(lines, "")
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "INSTALLATION                                            *terrareg-installation*"
  )
  table.insert(lines, "")
  table.insert(lines, "Using lazy.nvim: >")
  table.insert(lines, "    {")
  table.insert(lines, '      "remoterabbit/terrareg",')
  table.insert(lines, "      config = function()")
  table.insert(lines, '        require("terrareg").setup({})')
  table.insert(lines, "      end,")
  table.insert(lines, "    }")
  table.insert(lines, "<")
  table.insert(lines, "")
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "CONFIGURATION                                          *terrareg-configuration*"
  )
  table.insert(lines, "")
  table.insert(lines, "Default configuration: >")
  table.insert(lines, '    require("terrareg").setup({')
  table.insert(lines, "      option1 = true,")
  table.insert(lines, '      option2 = "default",')
  table.insert(lines, "    })")
  table.insert(lines, "<")
  table.insert(lines, "")
  table.insert(lines, "Configuration options:")
  table.insert(lines, "")
  table.insert(lines, "option1 (boolean, default: true)")
  table.insert(lines, "    Enable/disable feature 1")
  table.insert(lines, "")
  table.insert(lines, "option2 (string, default: 'default')")
  table.insert(lines, "    Configuration string")
  table.insert(lines, "")
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "USAGE                                                        *terrareg-usage*"
  )
  table.insert(lines, "")
  table.insert(lines, "[Add usage instructions here]")
  table.insert(lines, "")
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "API                                                            *terrareg-api*"
  )
  table.insert(lines, "")
  table.insert(lines, "setup({opts})                                          *terrareg.setup()*")
  table.insert(lines, "    Setup function for the plugin. Initializes the plugin with user")
  table.insert(lines, "    configuration.")
  table.insert(lines, "")
  table.insert(lines, "    Parameters: ~")
  table.insert(lines, "        {opts} (table|nil) User configuration options to override defaults")
  table.insert(lines, "")
  table.insert(lines, "get_config()                                      *terrareg.get_config()*")
  table.insert(lines, "    Get current configuration.")
  table.insert(lines, "")
  table.insert(lines, "    Returns: ~")
  table.insert(lines, "        (table) Current plugin configuration")
  table.insert(lines, "")
  table.insert(
    lines,
    "=============================================================================="
  )
  table.insert(
    lines,
    "LICENSE                                                    *terrareg-license*"
  )
  table.insert(lines, "")
  table.insert(lines, "GPL-3.0 License")
  table.insert(lines, "")
  table.insert(lines, "vim:tw=78:ts=8:ft=help:norl:")

  -- Ensure doc directory exists
  vim.fn.mkdir("doc", "p")

  -- Write the file
  local file = io.open("doc/terrareg.txt", "w")
  if file then
    file:write(table.concat(lines, "\n"))
    file:close()
    print("✅ Generated doc/terrareg.txt")
  else
    print("❌ Failed to write doc/terrareg.txt")
  end
end

M.generate = write_vimdoc

-- If called directly
if ... == nil then
  write_vimdoc()
end

return M
