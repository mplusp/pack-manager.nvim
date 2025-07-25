-- pack-manager.nvim v0.1.0
-- Enhanced commands for Neovim's built-in vim.pack plugin manager
-- 
-- This plugin only loads if vim.pack is available (Neovim 0.12+)

if vim.fn.has('nvim-0.12') == 0 or not vim.pack then
  return
end

-- Prevent loading twice
if vim.g.loaded_pack_manager then
  return
end
vim.g.loaded_pack_manager = 1

-- Load the main module
require('pack-manager').setup()