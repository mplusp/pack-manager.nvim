# pack-manager.nvim

[![Version](https://img.shields.io/badge/version-v0.5.0-blue.svg)](https://github.com/mplusp/pack-manager.nvim/releases/tag/v0.5.0)

Enhanced commands for Neovim's built-in `vim.pack` plugin manager.

This plugin provides a comprehensive set of user commands to manage plugins installed via Neovim 0.12+'s built-in `vim.pack` system, including safe removal, disabling/enabling, and bulk operations on inactive plugins.

## About This Project

This project, **pack-manager.nvim**, was created entirely as a collaborative effort between Marco Peluso (human developer) and Claude (Anthropic's AI assistant). Marco provided direction, requirements, and feedback, while Claude implemented all the code, documentation, and testing infrastructure based on those instructions.

This serves as a fun test project to explore Claude's capabilities in:
- Understanding complex Neovim plugin architecture
- Writing comprehensive Lua code with proper error handling
- Creating robust testing infrastructure
- Generating thorough documentation
- Following software engineering best practices

While we believe the plugin is functional and well-structured, **it has not been extensively tested in production environments**. 

**⚠️ USE AT YOUR OWN RISK**: This plugin directly manipulates your Neovim configuration files and plugin directories. We provide no warranties and cannot take responsibility for any damage, data loss, or issues that may occur from using this plugin. Always backup your configuration before use.

## Requirements

- Neovim 0.12+ (nightly builds)
- The built-in `vim.pack` functionality must be available

## Installation

Since this plugin is specifically designed to enhance Neovim's built-in `vim.pack` plugin manager, you should install it using `vim.pack` itself:

```lua
vim.pack.add({
  "https://github.com/mplusp/pack-manager.nvim"
})
```

## Features

- **Immediate plugin loading** - Plugins are available in current session after installation
- **Plugin updates** with single or bulk update support
- **Safe plugin removal** with confirmation prompts
- **Reversible disable/enable** system that preserves configurations
- **Bulk operations** for inactive plugins
- **Smart tab completion** for all commands
- **Automatic config cleanup** including `init.lua` modifications
- **Pattern-based removal** for bulk operations
- **Interactive removal** with numbered menus

## Commands

### Plugin Installation

#### `:PackAdd <plugin-name | owner/repo | full-url>`
Unified command that handles all plugin installation methods with intelligent configuration.

```
:PackAdd mason                          # Common plugin name
:PackAdd folke/tokyonight.nvim          # GitHub shorthand
:PackAdd https://github.com/neovim/nvim-lspconfig.git  # Full URL
```

After installation, plugins are immediately available in the current session - no restart required! For example, after `:PackAdd mason`, you can immediately run `:Mason` to open the Mason interface.

Features:
- **Multiple input formats** - Common plugin names, GitHub shorthand (`owner/repo`), or full URLs
- **Tab completion** - Auto-complete common plugin names for faster installation
- **Smart plugin detection** - Automatically categorizes plugins (colorschemes, LSP, UI, Git, etc.)
- **Interactive configuration** - Guided setup process with context-aware prompts
- **Automatic setup() calls** - Generates proper `require().setup()` calls for plugins that need them
- **Immediate loading** - Plugins are loaded and available in current session after installation
- **Colorscheme activation** - Option to immediately apply colorscheme plugins
- **Intelligent templates** - Creates appropriate config files based on plugin type
- **Duplicate installation checking** - Prevents installing the same plugin twice

**Common Plugin Names** (with tab completion):
- **LSP**: lspconfig, mason, lazydev, blink (auto-generates setup() calls)
- **File Management**: telescope, nvim-tree, oil, fzf-lua (with setup() calls)
- **Git**: gitsigns, fugitive (with setup() calls)
- **UI**: lualine, bufferline, noice, mini, nvim-web-devicons (with setup() calls)
- **Themes**: tokyonight, catppuccin, gruvbox, nord (with colorscheme activation option)
- **Utilities**: treesitter, plenary, harpoon (with setup() calls)
- **Development**: nvim-lint, nvim-dap (with setup() calls)

### Plugin Updates

#### `:PackUpdate [plugin_name]`
Updates a specific plugin or all plugins if no name is provided.

```
:PackUpdate                    # Update all plugins
:PackUpdate tokyonight.nvim    # Update specific plugin
```

Features:
- **Tab completion** for installed plugin names
- **Confirmation prompts** before updating
- **Single or bulk updates** - update one plugin or all at once
- **Safety checks** - verifies plugin exists before updating
- **Clear feedback** - shows what's being updated

#### `:PackUpdateAll`
Updates all installed plugins at once.

```
:PackUpdateAll
```

Features:
- **Bulk update** - updates all plugins in one command
- **Plugin listing** - shows all plugins before updating
- **Confirmation prompt** - requires user confirmation
- **Progress feedback** - clear status messages

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

#### `:PackDelTemp <plugin_name>`
Removes a plugin from disk temporarily. The plugin will be reinstalled on next Neovim restart if its configuration still exists.

- Tab completion available
- Confirmation prompt required
- Safe for testing plugin removal

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
│   └── plugins/
│       ├── plugin1.lua          # Individual plugin configs
│       ├── plugin2.lua
│       └── disabled/            # Disabled plugin configs
│           ├── plugin3.lua
│           └── plugin4.lua
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
5. **Test plugin removal** with `:PackDelTemp` before permanent removal

## Programmatic Usage

The plugin exports functions for programmatic use:

```lua
local pack_manager = require('pack-manager')

-- Update a specific plugin
pack_manager.update_plugin('tokyonight.nvim')

-- Update all plugins
pack_manager.update_plugin('')  -- Empty string updates all
-- OR
pack_manager.update_all_plugins()

-- Add a new plugin
pack_manager.add_plugin('folke/tokyonight.nvim')

-- Remove a plugin safely
pack_manager.safe_remove_plugin('some-plugin.nvim')

-- Disable a plugin
pack_manager.disable_plugin('some-plugin.nvim')

-- List inactive plugins
pack_manager.list_inactive_plugins()
```

## Troubleshooting

### Plugin reinstalls after removal
This happens when the plugin's config file still exists. Use `:PackDisable` or `:PackDelFull` instead of `:PackDelTemp`.

### Config file not found
The plugin assumes config files are in `lua/plugins/`. Adjust your structure or manually clean up files in different locations.

### Require statement not removed
The plugin looks for patterns like `require('plugins.plugin-name')`. If your require statements use a different pattern, you'll need to manually remove them.

### Permission errors
Ensure Neovim has write permissions to your config directory and plugin installation directories.

## Development

### Running Tests

The plugin includes a comprehensive test suite using the `busted` testing framework.

**Prerequisites:**
```bash
# Install luarocks if not already installed
brew install luarocks  # macOS
# or
sudo apt-get install luarocks  # Ubuntu

# Install testing dependencies
make install-deps
```

**Running tests:**
```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# Run tests continuously (requires entr)
make test-watch

# Run linter
make lint

# Or use the test script
./scripts/test.sh
```

**Test structure:**
```
tests/
├── minimal_init.lua          # Test environment setup
└── pack-manager/
    ├── utils_spec.lua        # Utility function tests
    └── init_spec.lua         # Main module tests
```

### Project Structure

```
pack-manager.nvim/
├── lua/
│   └── pack-manager/
│       ├── init.lua          # Main plugin logic
│       └── utils.lua         # Utility functions
├── plugin/
│   └── pack-manager.lua      # Plugin loader
├── doc/
│   └── pack-manager.txt      # Help documentation
├── tests/                    # Test suite
├── scripts/
│   └── test.sh              # Test runner script
├── .github/workflows/        # CI configuration
├── Makefile                  # Build automation
└── README.md
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `make test`
5. Run the linter: `make lint`
6. Submit a pull request

**Code style:**
- Follow existing Lua conventions
- Add tests for new functions
- Update documentation for new commands
- Use descriptive commit messages

## License

MIT License

Copyright (c) 2025 pack-manager.nvim contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.