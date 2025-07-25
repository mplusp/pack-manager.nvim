# pack-manager.nvim

Enhanced commands for Neovim's built-in `vim.pack` plugin manager.

This plugin provides a comprehensive set of user commands to manage plugins installed via Neovim 0.12+'s built-in `vim.pack` system, including safe removal, disabling/enabling, and bulk operations on inactive plugins.

## Requirements

- Neovim 0.12+ (nightly builds)
- The built-in `vim.pack` functionality must be available

## Installation

### Using vim.pack (Neovim 0.12+)

Add to your plugin configuration:

```lua
vim.pack.add({
  "path/to/pack-manager.nvim"
})
```

### Using other plugin managers

**lazy.nvim:**
```lua
{
  "path/to/pack-manager.nvim",
  cond = function()
    return vim.fn.has('nvim-0.12') == 1 and vim.pack ~= nil
  end,
}
```

**packer.nvim:**
```lua
use {
  "path/to/pack-manager.nvim",
  cond = function()
    return vim.fn.has('nvim-0.12') == 1 and vim.pack ~= nil
  end,
}
```

## Features

- **Safe plugin removal** with confirmation prompts
- **Reversible disable/enable** system that preserves configurations
- **Bulk operations** for inactive plugins
- **Smart tab completion** for all commands
- **Automatic config cleanup** including `init.lua` modifications
- **Pattern-based removal** for bulk operations
- **Interactive removal** with numbered menus

## Commands

### Basic Plugin Management

#### `:PackList`
Lists all installed plugins with their active/inactive status.

```
Installed plugins:
- mason.nvim (active)
- gitsigns.nvim (active)
- noice.nvim (inactive)
- nvim-treesitter (inactive)
```

#### `:PackCount`
Shows the total number of managed plugins.

#### `:PackInfo [plugin_name]`
Shows detailed information about a specific plugin or all plugins if no name is provided.

### Plugin Removal

#### `:PackDel <plugin_name>`
Removes a plugin from disk temporarily. The plugin will be reinstalled on next Neovim restart if its configuration still exists.

- Tab completion available
- Confirmation prompt required
- Safe for testing plugin removal

#### `:PackDelComplete <plugin_name>`
Removes a plugin and displays detailed cleanup instructions for permanent removal.

- Shows what files need to be manually cleaned up
- Includes require statement locations
- Good for learning the cleanup process

#### `:PackDelFull <plugin_name>`
Completely removes a plugin including its configuration files and require statements.

- **PERMANENT REMOVAL** - config files are deleted
- Automatically removes require lines from `init.lua`
- Prevents reinstallation on restart
- Most destructive option - use with caution

#### `:PackRemove`
Interactive removal with a numbered menu of all installed plugins.

```
Installed plugins:
1. mason.nvim
2. mini.nvim
3. gitsigns.nvim
Enter plugin number to remove (or 'q' to quit):
```

#### `:PackDelPattern <pattern>`
Removes all plugins matching a Lua pattern.

Example: `:PackDelPattern treesitter` removes all plugins with "treesitter" in the name.

### Disable/Enable System (Recommended)

The disable/enable system is the safest way to remove plugins temporarily while preserving their configurations.

#### `:PackDisable <plugin_name>`
Disables a plugin by:
- Removing it from disk with `vim.pack.del()`
- Moving config file to `lua/config/plugins/disabled/`
- Removing require statement from `init.lua`
- **Preventing reinstallation** on restart
- **Preserving configuration** for future re-enabling

#### `:PackEnable <plugin_name>`
Re-enables a previously disabled plugin by:
- Moving config file back from `disabled/` folder
- Providing instructions to add require statement back
- Plugin will be reinstalled on next restart

#### `:PackListDisabled`
Lists all disabled plugins that can be re-enabled.

### Inactive Plugin Management

Inactive plugins are those that `vim.pack` has marked as not active, usually due to missing dependencies or conflicts.

#### `:PackListInactive`
Lists only plugins with `active = false` status.

#### `:PackDelInactive`
Removes ALL inactive plugins from disk at once.
- Shows list before removal
- Requires confirmation
- Plugins will reinstall on restart unless configs are removed

#### `:PackDisableInactive` (Recommended)
Disables ALL inactive plugins permanently by:
- Moving all config files to `disabled/` folder
- Removing all require statements from `init.lua`
- Preventing reinstallation on restart
- **Preserving all configurations** for potential re-enabling

This is the safest way to clean up unused plugins.

## Configuration Structure Assumptions

This plugin assumes your Neovim configuration follows this structure:

```
~/.config/nvim/
├── init.lua                     # Contains require statements
├── lua/
│   └── config/
│       └── plugins/
│           ├── plugin1.lua      # Individual plugin configs
│           ├── plugin2.lua
│           └── disabled/        # Disabled plugin configs
│               ├── plugin3.lua
│               └── plugin4.lua
```

Each plugin config file should contain a `vim.pack.add()` call and the plugin's setup.

## Plugin Name Normalization

The plugin automatically normalizes plugin names by removing common suffixes:
- `fidget.nvim` becomes `fidget` for file operations
- `nvim-lspconfig` remains `nvim-lspconfig`
- `mini.nvim` becomes `mini`

This ensures compatibility between `vim.pack.get()` names and actual config file names.

## Safety Features

- **Confirmation prompts** for all destructive operations
- **Clear operation descriptions** before confirmation
- **Dry-run information** showing exactly what will be modified
- **Tab completion** to prevent typos
- **Graceful error handling** for missing files
- **Reversible operations** where possible

## Best Practices

1. **Use `:PackDisable`** instead of `:PackDelFull` when you might want to re-enable plugins later
2. **Use `:PackDisableInactive`** to safely clean up unused plugins
3. **Always review** the list of plugins before bulk operations
4. **Keep backups** of your configuration before major cleanup operations
5. **Test plugin removal** with `:PackDel` before permanent removal

## Programmatic Usage

The plugin exports functions for programmatic use:

```lua
local pack_manager = require('pack-manager')

-- Remove a plugin safely
pack_manager.safe_remove_plugin('some-plugin.nvim')

-- Disable a plugin
pack_manager.disable_plugin('some-plugin.nvim')

-- List inactive plugins
pack_manager.list_inactive_plugins()
```

## Troubleshooting

### Plugin reinstalls after removal
This happens when the plugin's config file still exists. Use `:PackDisable` or `:PackDelFull` instead of `:PackDel`.

### Config file not found
The plugin assumes config files are in `lua/config/plugins/`. Adjust your structure or manually clean up files in different locations.

### Require statement not removed
The plugin looks for patterns like `require('config.plugins.plugin-name')`. If your require statements use a different pattern, you'll need to manually remove them.

### Permission errors
Ensure Neovim has write permissions to your config directory and plugin installation directories.

## Contributing

This plugin was designed for personal use with a specific configuration structure. Feel free to modify it for your needs or submit improvements.

## License

MIT License - feel free to use and modify as needed.