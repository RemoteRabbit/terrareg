--- Terrareg plugin loader
-- @script plugin.terrareg

local vim = vim
if vim.g.loaded_terrareg == 1 then
  return
end

-- Plugin initialization
require("terrareg").setup()
