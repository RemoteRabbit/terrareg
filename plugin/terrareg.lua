-- terrareg.nvim - Terraform registry documentation plugin
-- Minimal plugin loader

-- Prevent loading twice
if vim.g.loaded_terrareg then
  return
end
vim.g.loaded_terrareg = 1

-- Plugin setup will be called by user in their config
-- require('terrareg').setup()
