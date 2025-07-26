-- UI utilities for pack-manager.nvim
-- Floating window system for better user experience

local M = {}

-- Test mode flag - when true, skip actual UI interaction
M._test_mode = _G._TEST or false

-- Default configuration for floating windows
local default_config = {
  relative = 'editor',
  style = 'minimal',
  border = 'rounded',
  title_pos = 'center',
}

-- Create a centered floating window
local function create_centered_window(width, height, title)
  local screen_w = vim.o.columns
  local screen_h = vim.o.lines

  local win_w = math.min(width, screen_w - 4)
  local win_h = math.min(height, screen_h - 4)

  local col = math.floor((screen_w - win_w) / 2)
  local row = math.floor((screen_h - win_h) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Window configuration
  local win_config = vim.tbl_extend('force', default_config, {
    width = win_w,
    height = win_h,
    col = col,
    row = row,
    title = title and (' ' .. title .. ' ') or nil,
  })

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'pack-manager')

  -- Set window options
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  return buf, win
end

-- Close floating window
local function close_window(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

-- Show a confirmation dialog with Yes/No options
function M.confirm(message, default_yes)
  local lines = vim.split(message, '\n')
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, #line)
  end

  -- Add space for buttons
  local button_line = default_yes and "[Y]es / [N]o" or "[y]es / [N]o"
  max_width = math.max(max_width, #button_line)

  local width = math.max(40, max_width + 4)
  local height = #lines + 4

  local buf, win = create_centered_window(width, height, "Confirmation")

  -- Set content
  local content = {}
  vim.list_extend(content, lines)
  table.insert(content, "")
  table.insert(content, button_line)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Position cursor on the button line
  vim.api.nvim_win_set_cursor(win, {#content, 0})

  local result = nil

  -- Key mappings
  local function set_result(value)
    result = value
    close_window(win)
  end

  -- Map keys
  local opts = { buffer = buf, noremap = true, silent = true }
  vim.keymap.set('n', 'y', function() set_result(true) end, opts)
  vim.keymap.set('n', 'Y', function() set_result(true) end, opts)
  vim.keymap.set('n', 'n', function() set_result(false) end, opts)
  vim.keymap.set('n', 'N', function() set_result(false) end, opts)
  vim.keymap.set('n', '<CR>', function()
    set_result(default_yes and true or false)
  end, opts)
  vim.keymap.set('n', '<Esc>', function() set_result(false) end, opts)
  vim.keymap.set('n', 'q', function() set_result(false) end, opts)

  -- Wait for user input (skip in test mode)
  if M._test_mode then
    close_window(win)
    -- Check if we have a test override for this specific message
    if M._test_responses and M._test_responses[message] ~= nil then
      return M._test_responses[message]
    end
    return default_yes and true or false
  end

  vim.cmd('redraw')
  while result == nil do
    vim.cmd('sleep 50m')
    vim.cmd('redraw')
  end

  return result
end

-- Show a selection dialog with multiple options
function M.select(message, options, default_index)
  local lines = vim.split(message, '\n')
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, #line)
  end

  -- Add option lines
  local option_lines = {}
  for i, option in ipairs(options) do
    local prefix = i == (default_index or 1) and "► " or "  "
    local line = string.format("%s%d. %s", prefix, i, option)
    table.insert(option_lines, line)
    max_width = math.max(max_width, #line)
  end

  local width = math.max(50, max_width + 4)
  local height = #lines + #option_lines + 4

  local buf, win = create_centered_window(width, height, "Select Option")

  -- Set content
  local content = {}
  vim.list_extend(content, lines)
  table.insert(content, "")
  vim.list_extend(content, option_lines)
  table.insert(content, "")
  table.insert(content, "Use ↑↓ or j/k to navigate, Enter to select, Esc/q to cancel")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Position cursor on first option
  local first_option_line = #lines + 2
  vim.api.nvim_win_set_cursor(win, {first_option_line, 0})

  local current_index = default_index or 1
  local result = nil

  -- Update cursor position and highlight
  local function update_display()
    -- Update option lines with current selection
    local updated_options = {}
    for i, option in ipairs(options) do
      local prefix = i == current_index and "► " or "  "
      local line = string.format("%s%d. %s", prefix, i, option)
      table.insert(updated_options, line)
    end

    -- Replace option lines
    local start_line = #lines + 1
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, start_line, start_line + #options, false, updated_options)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Position cursor
    vim.api.nvim_win_set_cursor(win, {start_line + current_index, 0})
  end

  local function set_result(value)
    result = value
    close_window(win)
  end

  -- Key mappings
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Navigation
  vim.keymap.set('n', 'j', function()
    current_index = math.min(current_index + 1, #options)
    update_display()
  end, opts)

  vim.keymap.set('n', 'k', function()
    current_index = math.max(current_index - 1, 1)
    update_display()
  end, opts)

  vim.keymap.set('n', '<Down>', function()
    current_index = math.min(current_index + 1, #options)
    update_display()
  end, opts)

  vim.keymap.set('n', '<Up>', function()
    current_index = math.max(current_index - 1, 1)
    update_display()
  end, opts)

  -- Number keys for direct selection
  for i = 1, math.min(#options, 9) do
    vim.keymap.set('n', tostring(i), function()
      set_result(i)
    end, opts)
  end

  -- Selection
  vim.keymap.set('n', '<CR>', function() set_result(current_index) end, opts)
  vim.keymap.set('n', '<Esc>', function() set_result(nil) end, opts)
  vim.keymap.set('n', 'q', function() set_result(nil) end, opts)

  -- Initial display
  update_display()

  -- Wait for user input (skip in test mode)
  if M._test_mode then
    close_window(win)
    return default_index or 1
  end

  vim.cmd('redraw')
  while result == nil do
    vim.cmd('sleep 50m')
    vim.cmd('redraw')
  end

  return result
end

-- Show an input dialog for text entry
function M.input(message, default_text)
  local lines = vim.split(message, '\n')
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, #line)
  end

  local width = math.max(60, max_width + 4)
  local height = #lines + 4

  local buf, win = create_centered_window(width, height, "Input")

  -- Set content
  local content = {}
  vim.list_extend(content, lines)
  table.insert(content, "")
  table.insert(content, default_text or "")
  table.insert(content, "")
  table.insert(content, "Enter text above, then press Ctrl+S to save or Esc to cancel")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

  -- Make only the input line editable
  local input_line = #lines + 2
  vim.api.nvim_win_set_cursor(win, {input_line, #(default_text or "")})

  -- Enable insert mode for the input line
  vim.cmd('startinsert!')

  local result = nil

  local function set_result(value)
    result = value
    close_window(win)
  end

  -- Key mappings
  local opts = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set('n', '<C-s>', function()
    local line = vim.api.nvim_buf_get_lines(buf, input_line - 1, input_line, false)[1]
    set_result(line)
  end, opts)

  vim.keymap.set('i', '<C-s>', function()
    local line = vim.api.nvim_buf_get_lines(buf, input_line - 1, input_line, false)[1]
    set_result(line)
  end, opts)

  vim.keymap.set({'n', 'i'}, '<Esc>', function()
    set_result(nil)
  end, opts)

  -- Restrict editing to input line only
  vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
    buffer = buf,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(win)
      if cursor[1] ~= input_line then
        vim.api.nvim_win_set_cursor(win, {input_line, cursor[2]})
      end
    end,
  })

  -- Wait for user input (skip in test mode)
  if M._test_mode then
    close_window(win)
    return default_text or ""
  end

  vim.cmd('redraw')
  while result == nil do
    vim.cmd('sleep 50m')
    vim.cmd('redraw')
  end

  return result
end

-- Show an informational message
function M.info(message, title)
  local lines = vim.split(message, '\n')
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, #line)
  end

  local width = math.max(50, max_width + 4)
  local height = #lines + 3

  local buf, win = create_centered_window(width, height, title or "Information")

  -- Set content
  local content = {}
  vim.list_extend(content, lines)
  table.insert(content, "")
  table.insert(content, "Press any key to continue...")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Position cursor
  vim.api.nvim_win_set_cursor(win, {#content, 0})

  local dismissed = false

  -- Key mapping for any key
  local opts = { buffer = buf, noremap = true, silent = true }

  local function dismiss()
    dismissed = true
    close_window(win)
  end

  -- Map common keys
  local keys = {'<CR>', '<Esc>', 'q', '<Space>', 'j', 'k', 'h', 'l'}
  for _, key in ipairs(keys) do
    vim.keymap.set('n', key, dismiss, opts)
  end

  -- Wait for dismissal (skip in test mode)
  if M._test_mode then
    close_window(win)
    return
  end

  vim.cmd('redraw')
  while not dismissed do
    vim.cmd('sleep 50m')
    vim.cmd('redraw')
  end
end

return M