-- Minimal init for testing
-- This sets up a minimal Neovim environment for testing
-- luacheck: globals vim

-- Add current directory to runtime path
vim.opt.rtp:prepend(".")

-- Required for testing
vim.opt.swapfile = false

-- Disable some unnecessary features for testing
vim.g.loaded_gzip = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Load plenary if available
local ok, _ = pcall(require, "plenary")
if not ok then
  local install_path = vim.fn.stdpath("data") .. "/site/pack/test/start/plenary.nvim"
  if vim.fn.isdirectory(install_path) == 0 then
    vim.fn.system({
      "git",
      "clone",
      "--depth=1",
      "https://github.com/nvim-lua/plenary.nvim.git",
      install_path,
    })
  end
  vim.opt.rtp:prepend(install_path)
end

-- Load our plugin
require("terrareg")
