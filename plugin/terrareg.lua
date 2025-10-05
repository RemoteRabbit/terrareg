--- Terrareg plugin loader
-- @script plugin.terrareg

if vim.g.loaded_terrareg == 1 then
  return
end

-- Plugin initialization
require("terrareg").setup()
