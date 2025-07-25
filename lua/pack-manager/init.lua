-- pack-manager.nvim
-- Enhanced commands for Neovim's built-in vim.pack plugin manager

local M = {}

-- Helper function to normalize plugin name for file/require paths
local function normalize_plugin_name(plugin_name)
  -- Remove common suffixes like .nvim, .vim, .lua
  local normalized = plugin_name:gsub("%.nvim$", ""):gsub("%.vim$", ""):gsub("%.lua$", "")
  return normalized
end

-- Safe removal - check if plugin is installed first
local function safe_remove_plugin(plugin_name)
  local installed_plugins = vim.pack.get()
  local found = false

  for _, plugin in ipairs(installed_plugins) do
    local name = plugin.spec and plugin.spec.name or ""
    local src = plugin.spec and plugin.spec.src or ""
    if name == plugin_name or src:match(plugin_name) then
      found = true
      break
    end
  end

  if not found then
    print("Plugin not found:", plugin_name)
    return
  end

  local confirm = vim.fn.input("Remove plugin '" .. plugin_name .. "'? (y/N): ")
  if confirm:lower() ~= 'y' then
    print("Cancelled")
    return
  end

  vim.pack.del({ plugin_name })
  print("Removed:", plugin_name)
end

-- Interactive plugin removal
local function remove_plugin_interactive()
  local plugins = vim.pack.get()
  local plugin_names = {}

  -- Get list of installed plugins
  for i, plugin in ipairs(plugins) do
    local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
    table.insert(plugin_names, name)
  end

  if #plugin_names == 0 then
    print("No plugins to remove")
    return
  end

  -- Show available plugins
  print("Installed plugins:")
  for i, name in ipairs(plugin_names) do
    print(i .. ". " .. name)
  end

  -- Get user input
  local choice = vim.fn.input("Enter plugin number to remove (or 'q' to quit): ")

  if choice == 'q' then
    return
  end

  local plugin_index = tonumber(choice)
  if plugin_index and plugin_index > 0 and plugin_index <= #plugin_names then
    local plugin_to_remove = plugin_names[plugin_index]
    local confirm = vim.fn.input("Remove plugin '" .. plugin_to_remove .. "'? (y/N): ")
    if confirm:lower() ~= 'y' then
      print("\nCancelled")
      return
    end
    vim.pack.del({ plugin_to_remove })
    print("\nRemoved: " .. plugin_to_remove)
  else
    print("Invalid selection")
  end
end

-- Complete plugin removal with cleanup reminders
local function remove_plugin_completely(plugin_name)
  -- Check if plugin exists
  local plugins = vim.pack.get()
  local found = false

  for _, plugin in ipairs(plugins) do
    local name = plugin.spec and plugin.spec.name or ""
    local src = plugin.spec and plugin.spec.src or ""
    if name == plugin_name or src:match(plugin_name) then
      found = true
      break
    end
  end

  if not found then
    print("Plugin not found:", plugin_name)
    return
  end

  local confirm = vim.fn.input("Remove plugin '" .. plugin_name .. "' and show cleanup instructions? (y/N): ")
  if confirm:lower() ~= 'y' then
    print("Cancelled")
    return
  end

  -- Remove the plugin
  vim.pack.del({ plugin_name })

  -- Clean up any related configuration
  print("Removed plugin:", plugin_name)
  print("IMPORTANT: To prevent reinstallation on restart, you must also:")
  print("1. Remove/comment the vim.pack.add() call from lua/config/plugins/" .. plugin_name .. ".lua")
  print("2. Remove the require() call from init.lua")
  print("3. Remove any plugin-specific keymaps and autocmds")
  print("4. Or simply delete the entire plugin file: lua/config/plugins/" .. plugin_name .. ".lua")
end

-- Remove all plugins matching a pattern
local function remove_plugins_by_pattern(pattern)
  local plugins = vim.pack.get()
  local to_remove = {}

  for i, plugin in ipairs(plugins) do
    local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
    if string.match(name, pattern) then
      table.insert(to_remove, name)
    end
  end

  if #to_remove == 0 then
    print("No plugins match pattern:", pattern)
    return
  end

  print("Removing plugins matching '" .. pattern .. "':")
  for _, name in ipairs(to_remove) do
    print("- " .. name)
  end

  local confirm = vim.fn.input("Continue? (y/N): ")
  if confirm:lower() == 'y' then
    vim.pack.del(to_remove)
    print("Removed " .. #to_remove .. " plugins")
  else
    print("Cancelled")
  end
end

-- Completely remove plugin including config files
local function remove_plugin_and_config(plugin_name)
  -- Check if plugin exists
  local plugins = vim.pack.get()
  local found = false

  for _, plugin in ipairs(plugins) do
    local name = plugin.spec and plugin.spec.name or ""
    local src = plugin.spec and plugin.spec.src or ""
    if name == plugin_name or src:match(plugin_name) then
      found = true
      break
    end
  end

  if not found then
    print("Plugin not found:", plugin_name)
    return
  end

  local normalized_name = normalize_plugin_name(plugin_name)
  local config_file = vim.fn.stdpath('config') .. "/lua/config/plugins/" .. normalized_name .. ".lua"

  print("This will PERMANENTLY remove:")
  print("- Plugin from disk: " .. plugin_name)
  print("- Config file: " .. config_file)
  print("- Require line from init.lua")

  local confirm = vim.fn.input("Are you sure? (y/N): ")
  if confirm:lower() ~= 'y' then
    print("Cancelled")
    return
  end

  -- Remove the plugin from disk
  vim.pack.del({ plugin_name })

  -- Try to remove config file
  if vim.fn.filereadable(config_file) == 1 then
    vim.fn.delete(config_file)
    print("Removed config file:", config_file)
  else
    print("Config file not found:", config_file)
  end

  -- Remove require line from init.lua
  local init_file = vim.fn.stdpath('config') .. "/init.lua"
  if vim.fn.filereadable(init_file) == 1 then
    local lines = vim.fn.readfile(init_file)
    local require_pattern = "require%('config%.plugins%." .. normalized_name:gsub("%-", "%%-") .. "'%)"
    local new_lines = {}
    local removed_line = false

    for _, line in ipairs(lines) do
      if not line:match(require_pattern) then
        table.insert(new_lines, line)
      else
        removed_line = true
        print("Removed require line: " .. line)
      end
    end

    if removed_line then
      vim.fn.writefile(new_lines, init_file)
      print("Updated init.lua")
    else
      print("No matching require line found in init.lua for pattern: config.plugins." .. normalized_name)
    end
  end

  print("Completely removed plugin:", plugin_name .. " (normalized: " .. normalized_name .. ")")
end

-- Disable plugin by moving config to disabled folder
local function disable_plugin(plugin_name)
  -- Check if plugin exists
  local plugins = vim.pack.get()
  local found = false

  for _, plugin in ipairs(plugins) do
    local name = plugin.spec and plugin.spec.name or ""
    local src = plugin.spec and plugin.spec.src or ""
    if name == plugin_name or src:match(plugin_name) then
      found = true
      break
    end
  end

  if not found then
    print("Plugin not found:", plugin_name)
    return
  end

  local normalized_name = normalize_plugin_name(plugin_name)
  local config_file = vim.fn.stdpath('config') .. "/lua/config/plugins/" .. normalized_name .. ".lua"
  local disabled_dir = vim.fn.stdpath('config') .. "/lua/config/plugins/disabled"
  local disabled_file = disabled_dir .. "/" .. normalized_name .. ".lua"

  print("This will disable plugin (reversible):")
  print("- Remove from disk: " .. plugin_name)
  print("- Move config: " .. config_file .. " -> " .. disabled_file)
  print("- Remove require line from init.lua")

  local confirm = vim.fn.input("Disable plugin? (y/N): ")
  if confirm:lower() ~= 'y' then
    print("Cancelled")
    return
  end

  -- Remove the plugin from disk
  vim.pack.del({ plugin_name })

  -- Create disabled directory if it doesn't exist
  vim.fn.mkdir(disabled_dir, "p")

  -- Move config file to disabled folder
  if vim.fn.filereadable(config_file) == 1 then
    if vim.fn.rename(config_file, disabled_file) == 0 then
      print("Moved config file to disabled folder: " .. disabled_file)
    else
      print("Failed to move config file")
    end
  else
    print("Config file not found:", config_file)
  end

  -- Remove require line from init.lua
  local init_file = vim.fn.stdpath('config') .. "/init.lua"
  if vim.fn.filereadable(init_file) == 1 then
    local lines = vim.fn.readfile(init_file)
    local require_pattern = "require%('config%.plugins%." .. normalized_name:gsub("%-", "%%-") .. "'%)"
    local new_lines = {}
    local removed_line = false

    for _, line in ipairs(lines) do
      if not line:match(require_pattern) then
        table.insert(new_lines, line)
      else
        removed_line = true
        print("Removed require line: " .. line)
      end
    end

    if removed_line then
      vim.fn.writefile(new_lines, init_file)
      print("Updated init.lua")
    else
      print("No matching require line found in init.lua for pattern: config.plugins." .. normalized_name)
    end
  end

  print("Plugin disabled:", plugin_name .. " (normalized: " .. normalized_name .. ")")
  print("To re-enable, use :PackEnable " .. plugin_name)
end

-- Enable plugin by moving config back from disabled folder
local function enable_plugin(plugin_name)
  local normalized_name = normalize_plugin_name(plugin_name)
  local config_file = vim.fn.stdpath('config') .. "/lua/config/plugins/" .. normalized_name .. ".lua"
  local disabled_dir = vim.fn.stdpath('config') .. "/lua/config/plugins/disabled"
  local disabled_file = disabled_dir .. "/" .. normalized_name .. ".lua"

  if vim.fn.filereadable(disabled_file) ~= 1 then
    print("Disabled plugin config not found:", disabled_file)
    return
  end

  if vim.fn.filereadable(config_file) == 1 then
    print("Plugin config already exists:", config_file)
    print("Remove it first or use a different name")
    return
  end

  print("This will re-enable plugin:")
  print("- Move config: " .. disabled_file .. " -> " .. config_file)
  print("- You'll need to manually add require line to init.lua")

  local confirm = vim.fn.input("Enable plugin? (y/N): ")
  if confirm:lower() ~= 'y' then
    print("Cancelled")
    return
  end

  -- Move config file back
  if vim.fn.rename(disabled_file, config_file) == 0 then
    print("Moved config file back: " .. config_file)
    print("Add this line to your init.lua:")
    print("require('config.plugins." .. normalized_name .. "')")
    print("Then restart Neovim or run :source % in init.lua")
  else
    print("Failed to move config file")
  end
end

-- List disabled plugins
local function list_disabled_plugins()
  local disabled_dir = vim.fn.stdpath('config') .. "/lua/config/plugins/disabled"
  local disabled_files = vim.fn.glob(disabled_dir .. "/*.lua", false, true)

  if #disabled_files == 0 then
    print("No disabled plugins found")
    return
  end

  print("Disabled plugins:")
  for _, file in ipairs(disabled_files) do
    local plugin_name = vim.fn.fnamemodify(file, ":t:r")
    print("- " .. plugin_name)
  end
end

-- Remove all inactive plugins
local function remove_inactive_plugins()
  local plugins = vim.pack.get()
  local inactive_plugins = {}

  -- Find all inactive plugins
  for _, plugin in ipairs(plugins) do
    if not plugin.active then
      local name = plugin.spec and plugin.spec.name or "Unknown Plugin"
      table.insert(inactive_plugins, name)
    end
  end

  if #inactive_plugins == 0 then
    print("No inactive plugins found")
    return
  end

  print("Found " .. #inactive_plugins .. " inactive plugins:")
  for _, name in ipairs(inactive_plugins) do
    print("- " .. name)
  end

  local confirm = vim.fn.input("Remove all inactive plugins from disk? (y/N): ")
  if confirm:lower() ~= 'y' then
    print("Cancelled")
    return
  end

  vim.pack.del(inactive_plugins)
  print("Removed " .. #inactive_plugins .. " inactive plugins")
  print("Note: They will reinstall on restart unless you remove their config files")
end

-- Disable all inactive plugins (move configs to disabled folder)
local function disable_inactive_plugins()
  local plugins = vim.pack.get()
  local inactive_plugins = {}

  -- Find all inactive plugins
  for _, plugin in ipairs(plugins) do
    if not plugin.active then
      local name = plugin.spec and plugin.spec.name or "Unknown Plugin"
      table.insert(inactive_plugins, name)
    end
  end

  if #inactive_plugins == 0 then
    print("No inactive plugins found")
    return
  end

  print("Found " .. #inactive_plugins .. " inactive plugins:")
  for _, name in ipairs(inactive_plugins) do
    print("- " .. name)
  end

  local confirm = vim.fn.input("Disable all inactive plugins? (move configs to disabled folder) (y/N): ")
  if confirm:lower() ~= 'y' then
    print("Cancelled")
    return
  end

  local disabled_count = 0
  local disabled_dir = vim.fn.stdpath('config') .. "/lua/config/plugins/disabled"
  vim.fn.mkdir(disabled_dir, "p")

  for _, plugin_name in ipairs(inactive_plugins) do
    local normalized_name = normalize_plugin_name(plugin_name)
    local config_file = vim.fn.stdpath('config') .. "/lua/config/plugins/" .. normalized_name .. ".lua"
    local disabled_file = disabled_dir .. "/" .. normalized_name .. ".lua"

    -- Move config file to disabled folder
    if vim.fn.filereadable(config_file) == 1 then
      if vim.fn.rename(config_file, disabled_file) == 0 then
        print("Moved " .. plugin_name .. " config to disabled folder")
        disabled_count = disabled_count + 1

        -- Remove require line from init.lua
        local init_file = vim.fn.stdpath('config') .. "/init.lua"
        if vim.fn.filereadable(init_file) == 1 then
          local lines = vim.fn.readfile(init_file)
          local require_pattern = "require%('config%.plugins%." .. normalized_name:gsub("%-", "%%-") .. "'%)"
          local new_lines = {}

          for _, line in ipairs(lines) do
            if not line:match(require_pattern) then
              table.insert(new_lines, line)
            end
          end

          vim.fn.writefile(new_lines, init_file)
        end
      end
    end
  end

  -- Remove plugins from disk
  vim.pack.del(inactive_plugins)

  print("Disabled " .. disabled_count .. " inactive plugins")
  print("Updated init.lua to remove require statements")
  print("Plugins will not reinstall on restart")
end

-- List only inactive plugins
local function list_inactive_plugins()
  local plugins = vim.pack.get()
  local inactive_plugins = {}

  for _, plugin in ipairs(plugins) do
    if not plugin.active then
      local name = plugin.spec and plugin.spec.name or "Unknown Plugin"
      table.insert(inactive_plugins, name)
    end
  end

  if #inactive_plugins == 0 then
    print("No inactive plugins found")
    return
  end

  print("Inactive plugins (" .. #inactive_plugins .. "):")
  for _, name in ipairs(inactive_plugins) do
    print("- " .. name)
  end
end

-- Setup function to create all commands
function M.setup()
  -- Handle cleanup when plugins are added, updated, or removed
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      print("Plugin changes detected. Current plugins:")
      local plugins = vim.pack.get()
      for i, plugin in ipairs(plugins) do
        local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
        local active = plugin.active
        print("- " .. name .. " (active: " .. tostring(active) .. ")")
      end
    end,
  })

  -- List all installed plugins
  vim.api.nvim_create_user_command('PackList', function()
    local plugins = vim.pack.get()
    print("Installed plugins:")

    if vim.tbl_isempty(plugins) then
      print("No plugins installed")
      return
    end

    for i, plugin in ipairs(plugins) do
      local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
      local status = plugin.active and "active" or "inactive"
      print("- " .. name .. " (" .. status .. ")")
    end
  end, {})

  -- Remove a specific plugin with tab completion
  vim.api.nvim_create_user_command('PackDel', function(opts)
    if opts.args == "" then
      print("Usage: :PackDel <plugin_name>")
      return
    end

    local confirm = vim.fn.input("Remove plugin '" .. opts.args .. "' from disk? (will reinstall on restart) (y/N): ")
    if confirm:lower() ~= 'y' then
      print("Cancelled")
      return
    end

    vim.pack.del({ opts.args })
    print("Removed plugin:", opts.args)
  end, {
    nargs = 1,
    complete = function()
      local plugins = vim.pack.get()
      local names = {}
      for i, plugin in ipairs(plugins) do
        local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
        table.insert(names, name)
      end
      return names
    end
  })

  -- Interactive plugin removal command
  vim.api.nvim_create_user_command('PackRemove', remove_plugin_interactive, {})

  -- Remove plugin with cleanup reminders
  vim.api.nvim_create_user_command('PackDelComplete', function(opts)
    if opts.args == "" then
      print("Usage: :PackDelComplete <plugin_name>")
      return
    end

    remove_plugin_completely(opts.args)
  end, {
    nargs = 1,
    complete = function()
      local plugins = vim.pack.get()
      local names = {}
      for i, plugin in ipairs(plugins) do
        local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
        table.insert(names, name)
      end
      return names
    end
  })

  -- Remove plugins by pattern
  vim.api.nvim_create_user_command('PackDelPattern', function(opts)
    if opts.args == "" then
      print("Usage: :PackDelPattern <pattern>")
      return
    end

    remove_plugins_by_pattern(opts.args)
  end, { nargs = 1 })

  -- Show detailed plugin information
  vim.api.nvim_create_user_command('PackInfo', function(opts)
    if opts.args == "" then
      -- Show all plugins info
      local plugins = vim.pack.get()
      print("Plugin information:")
      print(vim.inspect(plugins))
    else
      -- Show specific plugin info
      local plugins = vim.pack.get()
      local found_plugin = nil

      for i, plugin in ipairs(plugins) do
        local name = plugin.spec and plugin.spec.name or ""
        local src = plugin.spec and plugin.spec.src or ""
        if name == opts.args or src:match(opts.args) then
          found_plugin = plugin
          break
        end
      end

      if found_plugin then
        print("Plugin info for '" .. opts.args .. "':")
        print(vim.inspect(found_plugin))
      else
        print("Plugin not found:", opts.args)
      end
    end
  end, {
    nargs = '?',
    complete = function()
      local plugins = vim.pack.get()
      local names = {}
      for i, plugin in ipairs(plugins) do
        local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
        table.insert(names, name)
      end
      return names
    end
  })

  -- Count installed plugins
  vim.api.nvim_create_user_command('PackCount', function()
    local plugins = vim.pack.get()
    local count = #plugins
    print("Total plugins managed by vim.pack:", count)
  end, {})

  -- Complete removal command
  vim.api.nvim_create_user_command('PackDelFull', function(opts)
    if opts.args == "" then
      print("Usage: :PackDelFull <plugin_name>")
      return
    end

    remove_plugin_and_config(opts.args)
  end, {
    nargs = 1,
    complete = function()
      local plugins = vim.pack.get()
      local names = {}
      for i, plugin in ipairs(plugins) do
        local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
        table.insert(names, name)
      end
      return names
    end
  })

  -- Disable/Enable commands
  vim.api.nvim_create_user_command('PackDisable', function(opts)
    if opts.args == "" then
      print("Usage: :PackDisable <plugin_name>")
      return
    end

    disable_plugin(opts.args)
  end, {
    nargs = 1,
    complete = function()
      local plugins = vim.pack.get()
      local names = {}
      for i, plugin in ipairs(plugins) do
        local name = plugin.spec and plugin.spec.name or "Unknown Plugin " .. i
        table.insert(names, name)
      end
      return names
    end
  })

  vim.api.nvim_create_user_command('PackEnable', function(opts)
    if opts.args == "" then
      print("Usage: :PackEnable <plugin_name>")
      return
    end

    enable_plugin(opts.args)
  end, {
    nargs = 1,
    complete = function()
      local disabled_dir = vim.fn.stdpath('config') .. "/lua/config/plugins/disabled"
      local disabled_files = vim.fn.glob(disabled_dir .. "/*.lua", false, true)
      local names = {}
      for _, file in ipairs(disabled_files) do
        local plugin_name = vim.fn.fnamemodify(file, ":t:r")
        table.insert(names, plugin_name)
      end
      return names
    end
  })

  vim.api.nvim_create_user_command('PackListDisabled', list_disabled_plugins, {})

  -- Inactive plugin commands
  vim.api.nvim_create_user_command('PackListInactive', list_inactive_plugins, {})
  vim.api.nvim_create_user_command('PackDelInactive', remove_inactive_plugins, {})
  vim.api.nvim_create_user_command('PackDisableInactive', disable_inactive_plugins, {})
end

-- Export functions for programmatic use
M.safe_remove_plugin = safe_remove_plugin
M.remove_plugin_interactive = remove_plugin_interactive
M.remove_plugin_completely = remove_plugin_completely
M.remove_plugins_by_pattern = remove_plugins_by_pattern
M.remove_plugin_and_config = remove_plugin_and_config
M.disable_plugin = disable_plugin
M.enable_plugin = enable_plugin
M.list_disabled_plugins = list_disabled_plugins
M.remove_inactive_plugins = remove_inactive_plugins
M.disable_inactive_plugins = disable_inactive_plugins
M.list_inactive_plugins = list_inactive_plugins

return M