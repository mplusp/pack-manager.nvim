-- Minimal init for testing pack-manager.nvim

-- Set test flag
_G._TEST = true

-- Create global vim table if it doesn't exist
vim = vim or {}

-- Set up package path for testing
local pack_manager_path = vim.fn and vim.fn.getcwd() or "."
package.path = pack_manager_path .. "/lua/?.lua;" .. package.path

-- Mock vim.pack for testing
if not vim.pack then
  vim.pack = {
    get = function()
      return {}
    end,
    add = function(specs)
      -- Mock implementation
    end,
    del = function(names)
      -- Mock implementation
    end,
    update = function()
      -- Mock implementation
    end
  }
end

-- Mock vim functions commonly used in the plugin
vim.fn = vim.fn or {}
vim.fn.stdpath = vim.fn.stdpath or function(what)
  if what == 'config' then
    return '/tmp/nvim-test-config'
  end
  return '/tmp/nvim-test'
end

vim.fn.mkdir = vim.fn.mkdir or function(path, flags)
  return 0 -- success
end

vim.fn.filereadable = vim.fn.filereadable or function(file)
  return 0 -- not readable by default
end

vim.fn.readfile = vim.fn.readfile or function(file)
  return {}
end

vim.fn.writefile = vim.fn.writefile or function(lines, file)
  return 0 -- success
end

vim.fn.delete = vim.fn.delete or function(file)
  return 0 -- success
end

vim.fn.rename = vim.fn.rename or function(old, new)
  return 0 -- success
end

vim.fn.glob = vim.fn.glob or function(pattern, nosuf, list)
  return list and {} or ""
end

vim.fn.fnamemodify = vim.fn.fnamemodify or function(fname, mods)
  if mods == ":t:r" then
    return fname:match("([^/]+)%.lua$") or fname
  end
  return fname
end

vim.fn.input = vim.fn.input or function(prompt)
  return "y" -- Default to yes for testing
end

-- Mock vim.api functions
vim.api = vim.api or {}
vim.api.nvim_create_user_command = vim.api.nvim_create_user_command or function(name, command, opts) end
vim.api.nvim_create_autocmd = vim.api.nvim_create_autocmd or function(events, opts) end
vim.api.nvim_create_augroup = vim.api.nvim_create_augroup or function(name, opts)
  return 1
end

-- Mock vim.tbl_isempty
vim.tbl_isempty = vim.tbl_isempty or function(t)
  return next(t) == nil
end

-- Mock vim.inspect
vim.inspect = vim.inspect or function(obj)
  return tostring(obj)
end

-- Mock vim.g for plugin loading guard
vim.g = vim.g or {}

-- Mock vim.cmd
vim.cmd = vim.cmd or {
  colorscheme = function(name)
    -- Mock implementation
  end
}
