-- Utility functions for pack-manager.nvim
-- Separated for easier testing

local M = {}

-- Helper function to normalize plugin name for file/require paths
function M.normalize_plugin_name(plugin_name)
  -- Remove common suffixes like .nvim, .vim, .lua
  local normalized = plugin_name:gsub("%.nvim$", ""):gsub("%.vim$", ""):gsub("%.lua$", "")
  return normalized
end

-- Parse plugin specification into components
function M.parse_plugin_spec(plugin_spec)
  local plugin_url, plugin_name, plugin_version
  
  -- Handle different input formats
  if plugin_spec:match("^https?://") then
    -- Full URL provided
    plugin_url = plugin_spec
    plugin_name = plugin_url:match("/([^/]+)%.git$") or plugin_url:match("/([^/]+)$")
    plugin_name = plugin_name and plugin_name:gsub("%.git$", "")
  elseif plugin_spec:match("^[%w_%-]+/[%w_%-%.]+") then
    -- GitHub shorthand (owner/repo)
    plugin_url = "https://github.com/" .. plugin_spec .. ".git"
    plugin_name = plugin_spec:match("/([^/]+)$")
  else
    return nil, "Invalid plugin specification. Use 'owner/repo' or full URL."
  end

  if not plugin_name then
    return nil, "Could not determine plugin name from: " .. plugin_spec
  end

  return {
    url = plugin_url,
    name = plugin_name,
    version = plugin_version or "main"
  }, nil
end

-- Check if plugin is already installed
function M.is_plugin_installed(plugin_name)
  local plugins = vim.pack.get()
  for _, plugin in ipairs(plugins) do
    local existing_name = plugin.spec and plugin.spec.name or ""
    if existing_name == plugin_name then
      return true, plugin
    end
  end
  return false, nil
end

-- Find plugin by name or partial match
function M.find_plugin(plugin_name)
  local plugins = vim.pack.get()
  for _, plugin in ipairs(plugins) do
    local name = plugin.spec and plugin.spec.name or ""
    local src = plugin.spec and plugin.spec.src or ""
    if name == plugin_name or src:match(plugin_name) then
      return plugin
    end
  end
  return nil
end

-- Get list of inactive plugins
function M.get_inactive_plugins()
  local plugins = vim.pack.get()
  local inactive_plugins = {}

  for _, plugin in ipairs(plugins) do
    if not plugin.active then
      local name = plugin.spec and plugin.spec.name or "Unknown Plugin"
      table.insert(inactive_plugins, name)
    end
  end

  return inactive_plugins
end

-- Get list of disabled plugins (from disabled folder)
function M.get_disabled_plugins()
  local disabled_dir = vim.fn.stdpath('config') .. "/lua/config/plugins/disabled"
  local disabled_files = vim.fn.glob(disabled_dir .. "/*.lua", false, true)
  local disabled_plugins = {}

  for _, file in ipairs(disabled_files) do
    local plugin_name = vim.fn.fnamemodify(file, ":t:r")
    table.insert(disabled_plugins, plugin_name)
  end

  return disabled_plugins
end

-- Validate plugin name format
function M.validate_plugin_name(name)
  if not name or name == "" then
    return false, "Plugin name cannot be empty"
  end
  
  if name:match("^%s*$") then
    return false, "Plugin name cannot be only whitespace"
  end
  
  return true, nil
end

-- Create file path for plugin config
function M.get_plugin_config_path(plugin_name)
  local normalized_name = M.normalize_plugin_name(plugin_name)
  return vim.fn.stdpath('config') .. "/lua/config/plugins/" .. normalized_name .. ".lua"
end

-- Create file path for disabled plugin config
function M.get_disabled_config_path(plugin_name)
  local normalized_name = M.normalize_plugin_name(plugin_name)
  local disabled_dir = vim.fn.stdpath('config') .. "/lua/config/plugins/disabled"
  return disabled_dir .. "/" .. normalized_name .. ".lua"
end

return M