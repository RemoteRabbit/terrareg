if vim.g.loaded_terrareg == 1 then
  return
end
vim.g.loaded_terrareg = 1

-- Plugin initialization
require("terrareg").setup()
