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

-- Mock vim.split function for older Neovim versions
vim.split = vim.split or function(s, sep, plain)
  local result = {}
  if not s or s == "" then
    return result
  end
  
  if not sep or sep == "" then
    -- Split by lines if no separator provided
    sep = "\n"
  end
  
  local pattern = plain and sep:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") or sep
  local start = 1
  local sep_start, sep_end = s:find(pattern, start)
  
  while sep_start do
    table.insert(result, s:sub(start, sep_start - 1))
    start = sep_end + 1
    sep_start, sep_end = s:find(pattern, start)
  end
  
  -- Add the last part
  table.insert(result, s:sub(start))
  
  return result
end

-- Mock vim.api functions
vim.api = vim.api or {}
vim.api.nvim_create_user_command = vim.api.nvim_create_user_command or function(name, command, opts) end
vim.api.nvim_create_buf = vim.api.nvim_create_buf or function(listed, scratch) return 1 end
vim.api.nvim_open_win = vim.api.nvim_open_win or function(buf, enter, config) return 1 end
vim.api.nvim_win_is_valid = vim.api.nvim_win_is_valid or function(win) return true end
vim.api.nvim_win_close = vim.api.nvim_win_close or function(win, force) end
vim.api.nvim_buf_set_option = vim.api.nvim_buf_set_option or function(buf, option, value) end
vim.api.nvim_win_set_option = vim.api.nvim_win_set_option or function(win, option, value) end
vim.api.nvim_buf_set_lines = vim.api.nvim_buf_set_lines or function(buf, start, end_, strict_indexing, replacement) end
vim.api.nvim_win_set_cursor = vim.api.nvim_win_set_cursor or function(win, pos) end
vim.api.nvim_buf_get_lines = vim.api.nvim_buf_get_lines or function(buf, start, end_, strict_indexing) return {""} end
vim.api.nvim_create_autocmd = vim.api.nvim_create_autocmd or function(events, opts) end

-- Mock vim.keymap
vim.keymap = vim.keymap or {}
vim.keymap.set = vim.keymap.set or function(mode, lhs, rhs, opts) end

-- Mock vim.o and vim.cmd
vim.o = vim.o or { columns = 80, lines = 24 }
vim.cmd = vim.cmd or function(cmd) end

-- Mock vim.tbl_extend
vim.tbl_extend = vim.tbl_extend or function(behavior, ...)
  local result = {}
  for _, tbl in ipairs({...}) do
    for k, v in pairs(tbl) do
      result[k] = v
    end
  end
  return result
end

-- Mock vim.list_extend
vim.list_extend = vim.list_extend or function(dst, src, start, finish)
  start = start or 1
  finish = finish or #src
  for i = start, finish do
    table.insert(dst, src[i])
  end
  return dst
end
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
