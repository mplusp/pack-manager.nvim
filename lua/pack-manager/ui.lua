-- UI utilities for pack-manager.nvim
-- Floating window system for better user experience

local M = {}

-- Test mode flag - when true, skip actual UI interaction
M._test_mode = _G._TEST or false

-- Precompute special key codes (with fallback for test environment)
local special_keys = {}
if vim.api and vim.api.nvim_replace_termcodes then
  special_keys.up = vim.api.nvim_replace_termcodes("<Up>", true, true, true)
  special_keys.down = vim.api.nvim_replace_termcodes("<Down>", true, true, true)
  special_keys.esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
else
  -- Fallback for test environment
  special_keys.up = "\128\253\107"   -- Neovim's internal representation
  special_keys.down = "\128\253\108" -- Neovim's internal representation
  special_keys.esc = "\27"           -- ESC character
end

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

  -- Wait for user input (skip in test mode)
  if M._test_mode then
    close_window(win)
    -- Check if we have a test override for this specific message
    if M._test_responses and M._test_responses[message] ~= nil then
      return M._test_responses[message]
    end
    return default_yes and true or false
  end

  -- Use vim.fn.getchar() to wait for input properly
  local key
  repeat
    vim.cmd('redraw')
    key = vim.fn.getchar()

    -- Handle different key types
    if type(key) == "string" then
      -- For confirm dialog, we'll ignore arrow keys but handle single ESC
      local bytes = {key:byte(1, -1)}
      if #bytes == 1 and bytes[1] == 27 then
        result = false
      end
      -- Ignore other escape sequences like arrow keys
    elseif type(key) == "number" then
      if key == string.byte('y') or key == string.byte('Y') then
        result = true
      elseif key == string.byte('n') or key == string.byte('N') then
        result = false
      elseif key == 13 then -- Enter key
        result = default_yes and true or false
      elseif key == 27 then -- Escape key
        result = false
      elseif key == string.byte('q') or key == string.byte('Q') then
        result = false
      end
    end
  until result ~= nil

  close_window(win)
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


  -- Initial display
  update_display()

  -- Wait for user input (skip in test mode)
  if M._test_mode then
    close_window(win)
    return default_index or 1
  end

  -- Use vim.fn.getchar() to wait for input properly
  local done = false
  local key
  repeat
    vim.cmd('redraw')
    key = vim.fn.getchar()

    -- Handle different key types
    if type(key) == "string" then
      -- Handle special keys (arrow keys come as strings starting with 0x80)
      if key == special_keys.up then
        current_index = math.max(current_index - 1, 1)
        update_display()
      elseif key == special_keys.down then
        current_index = math.min(current_index + 1, #options)
        update_display()
      elseif key == special_keys.esc then
        result = nil
        done = true
      else
        -- Handle legacy escape sequences for compatibility
        local bytes = {key:byte(1, -1)}
        if #bytes == 3 and bytes[1] == 27 and bytes[2] == 91 then
          -- ESC[A = Up, ESC[B = Down (for older terminals)
          if bytes[3] == 65 then -- Up arrow
            current_index = math.max(current_index - 1, 1)
            update_display()
          elseif bytes[3] == 66 then -- Down arrow
            current_index = math.min(current_index + 1, #options)
            update_display()
          end
        end
      end
    elseif type(key) == "number" then
      -- Handle regular keys
      if key == string.byte('j') or key == string.byte('J') then
        current_index = math.min(current_index + 1, #options)
        update_display()
      elseif key == string.byte('k') or key == string.byte('K') then
        current_index = math.max(current_index - 1, 1)
        update_display()
      elseif key >= string.byte('1') and key <= string.byte('9') then
        local selected = key - string.byte('0')
        if selected <= #options then
          result = selected
          done = true
        end
      elseif key == 13 then -- Enter key
        result = current_index
        done = true
      elseif key == 27 then -- Escape key (single ESC)
        result = nil
        done = true
      elseif key == string.byte('q') or key == string.byte('Q') then
        result = nil
        done = true
      end
    end

    -- Ignore unhandled escape sequences
  until done

  close_window(win)
  return result
end

-- Show an input dialog for text entry
-- For now, fall back to vim.fn.input to avoid complexity
function M.input(message, default_text)
  -- In test mode, return default
  if M._test_mode then
    return default_text or ""
  end

  -- Use vim.fn.input as fallback for now
  return vim.fn.input(message .. (default_text and (" [" .. default_text .. "]: ") or ": "), default_text or "")
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


  -- Wait for dismissal (skip in test mode)
  if M._test_mode then
    close_window(win)
    return
  end

  -- Use vim.fn.getchar() to wait for any key
  vim.cmd('redraw')
  vim.fn.getchar()
  close_window(win)
end

-- Show a central menu similar to Mason's interface
function M.menu()
  local menu_options = {
    { key = "1", label = "Add Plugin", desc = "Install a new plugin", action = "add" },
    { key = "2", label = "List Plugins", desc = "Show all installed plugins", action = "list" },
    { key = "3", label = "Update Plugins", desc = "Update installed plugins", action = "update" },
    { key = "4", label = "Remove Plugin", desc = "Remove a plugin", action = "remove" },
    { key = "5", label = "Disable Plugin", desc = "Disable a plugin temporarily", action = "disable" },
    { key = "6", label = "Enable Plugin", desc = "Re-enable a disabled plugin", action = "enable" },
    { key = "7", label = "Manage Inactive", desc = "Handle inactive plugins", action = "inactive" },
    { key = "8", label = "Plugin Info", desc = "Show plugin information", action = "info" },
  }

  -- Calculate dimensions
  local max_label_width = 0
  local max_desc_width = 0
  for _, option in ipairs(menu_options) do
    max_label_width = math.max(max_label_width, #option.label)
    max_desc_width = math.max(max_desc_width, #option.desc)
  end

  local content_width = 6 + max_label_width + 3 + max_desc_width -- "► 1. " + label + " - " + desc
  local width = math.max(60, content_width + 6) -- padding
  local height = #menu_options + 6 -- options + header + footer + padding

  local buf, win = create_centered_window(width, height, "Pack Manager")

  -- Header lines
  local header_lines = {"Choose an action:", ""}

  -- Current selection
  local current_index = 1

  -- Update function to show cursor
  local function update_display()
    local content = {}
    vim.list_extend(content, header_lines)

    for i, option in ipairs(menu_options) do
      local prefix = i == current_index and "► " or "  "
      local line = string.format("%s%s. %-" .. max_label_width .. "s - %s",
                                 prefix, option.key, option.label, option.desc)
      table.insert(content, line)
    end

    table.insert(content, "")
    table.insert(content, "Use ↑↓ or j/k to navigate, Enter to select, number key for quick select, q/Esc to quit")

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Position cursor on current option
    vim.api.nvim_win_set_cursor(win, {2 + current_index, 0})
  end

  -- Initial display
  update_display()

  local result = nil -- luacheck: ignore 311

  -- Wait for user input (skip in test mode)
  if M._test_mode then
    close_window(win)
    return "add" -- default for testing
  end

  -- Use vim.fn.getchar() to wait for input properly
  local done = false
  local key
  repeat
    vim.cmd('redraw')
    key = vim.fn.getchar()

    -- Debug: uncomment to see key values
    -- vim.notify(string.format("Key type: %s, value: %s", type(key), vim.inspect(key)))

    -- Handle different key types
    if type(key) == "string" then
      -- Handle special keys (arrow keys come as strings starting with 0x80)
      if key == special_keys.up then
        current_index = math.max(current_index - 1, 1)
        update_display()
      elseif key == special_keys.down then
        current_index = math.min(current_index + 1, #menu_options)
        update_display()
      elseif key == special_keys.esc then
        result = nil
        done = true
      else
        -- Handle legacy escape sequences and regular character strings
        local bytes = {key:byte(1, -1)}
        if #bytes == 3 and bytes[1] == 27 and bytes[2] == 91 then
          -- ESC[A = Up, ESC[B = Down (for older terminals)
          if bytes[3] == 65 then -- Up arrow
            current_index = math.max(current_index - 1, 1)
            update_display()
          elseif bytes[3] == 66 then -- Down arrow
            current_index = math.min(current_index + 1, #menu_options)
            update_display()
          end
        elseif #bytes == 1 and bytes[1] == 27 then
          -- Single ESC
          result = nil
          done = true
        elseif #bytes == 1 then
          -- Handle single character strings
          local char = string.char(bytes[1])
          if char == 'j' or char == 'J' then
            current_index = math.min(current_index + 1, #menu_options)
            update_display()
          elseif char == 'k' or char == 'K' then
            current_index = math.max(current_index - 1, 1)
            update_display()
          elseif char >= '1' and char <= '8' then
            local selected = string.byte(char) - string.byte('0')
            if selected <= #menu_options then
              result = menu_options[selected].action
              done = true
            end
          elseif char == 'q' or char == 'Q' then
            result = nil
            done = true
          end
        end
      end
    elseif type(key) == "number" then
      -- Handle regular keys and special keycodes
      if key == string.byte('j') or key == string.byte('J') then
        current_index = math.min(current_index + 1, #menu_options)
        update_display()
      elseif key == string.byte('k') or key == string.byte('K') then
        current_index = math.max(current_index - 1, 1)
        update_display()
      elseif key >= string.byte('1') and key <= string.byte('8') then
        local selected = key - string.byte('0')
        if selected <= #menu_options then
          result = menu_options[selected].action
          done = true
        end
      elseif key == 13 then -- Enter key
        result = menu_options[current_index].action
        done = true
      elseif key == 27 then -- Escape key
        result = nil
        done = true
      elseif key == string.byte('q') or key == string.byte('Q') then
        result = nil
        done = true
      end
    end
  until done

  close_window(win)
  return result
end

return M