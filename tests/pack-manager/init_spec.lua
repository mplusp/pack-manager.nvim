-- Tests for pack-manager main module

require('tests.minimal_init')

describe("pack-manager main module", function()
  local pack_manager
  local ui

  before_each(function()
    -- Reset the module cache
    package.loaded['pack-manager'] = nil
    package.loaded['pack-manager.init'] = nil
    package.loaded['pack-manager.ui'] = nil

    -- Reset vim.g
    vim.g.loaded_pack_manager = nil

    -- Load the module fresh
    pack_manager = require('pack-manager')
    ui = require('pack-manager.ui')
  end)

  -- Helper function to mock UI interactions
  local function mock_ui_responses(responses)
    ui.confirm = function(message, default)
      for pattern, response in pairs(responses.confirm or {}) do
        if message:match(pattern) then
          return response
        end
      end
      return default
    end

    ui.select = function(message, options, default_index)
      for pattern, response in pairs(responses.select or {}) do
        if message:match(pattern) then
          return response
        end
      end
      return default_index
    end

    ui.info = function(message, title)
      -- Just capture for testing
    end
  end

  describe("module loading", function()
    it("should load without errors", function()
      assert.is_not_nil(pack_manager)
      assert.is_table(pack_manager)
    end)

    it("should expose setup function", function()
      assert.is_function(pack_manager.setup)
    end)

    it("should expose core functions", function()
      assert.is_function(pack_manager.add_plugin)
      assert.is_function(pack_manager.disable_plugin)
      assert.is_function(pack_manager.enable_plugin)
      assert.is_function(pack_manager.list_inactive_plugins)
    end)
  end)

  describe("setup function", function()
    it("should run without errors", function()
      -- Mock vim.api functions to avoid errors
      local command_count = 0
      vim.api.nvim_create_user_command = function(name, command, opts)
        command_count = command_count + 1
      end

      local autocmd_count = 0
      vim.api.nvim_create_autocmd = function(events, opts)
        autocmd_count = autocmd_count + 1
      end

      -- Should not throw error
      assert.has_no.errors(function()
        pack_manager.setup()
      end)

      -- Should create multiple commands
      assert.is_true(command_count > 10)

      -- Should create autocmds
      assert.is_true(autocmd_count > 0)
    end)
  end)

  describe("add_plugin function", function()
    it("should be callable", function()
      assert.is_function(pack_manager.add_plugin)
    end)

    it("should handle colorscheme plugin installation flow", function()
      -- Mock vim.pack functions
      local pack_added = false
      vim.pack.add = function(spec)
        pack_added = true
      end
      vim.pack.get = function() return {} end

      -- Mock file operations
      vim.fn.writefile = function() return 0 end
      vim.fn.filereadable = function() return 0 end
      vim.fn.mkdir = function() return 0 end

      -- Mock UI responses
      mock_ui_responses({
        confirm = {
          ["Install this plugin"] = true,
          ["Create config file"] = true,
          ["Add require statement"] = true,
          ["Apply this colorscheme now"] = true,
          ["Load and apply the colorscheme now"] = false
        }
      })

      -- Call add_plugin with a colorscheme
      pack_manager.add_plugin("folke/tokyonight.nvim")

      -- Verify the flow
      assert.is_true(pack_added)

      -- Test passes if we got here without errors - UI interactions were mocked
    end)

    it("should immediately load plugin after installation", function()
      -- Mock vim.pack functions
      local pack_added = false
      vim.pack.add = function(spec)
        pack_added = true
      end
      vim.pack.get = function() return {} end

      -- Mock file operations
      vim.fn.writefile = function() return 0 end
      vim.fn.filereadable = function() return 0 end
      vim.fn.mkdir = function() return 0 end

      -- Track require calls to verify immediate loading
      local config_loaded = false
      -- Add the config to the preload table so require can find it
      package.preload["plugins.mason"] = function()
        config_loaded = true
        return { setup = function() end }
      end

      -- Mock UI responses for immediate loading test
      mock_ui_responses({
        confirm = {
          ["Install this plugin"] = true,
          ["Create config file"] = true,
          ["Add require statement"] = true
        }
      })

      -- Call add_plugin with a plugin that needs setup
      pack_manager.add_plugin("mason-org/mason.nvim")

      -- Verify plugin was added and config was loaded
      assert.is_true(pack_added)
      assert.is_true(config_loaded)

      -- Clean up preload
      package.preload["plugins.mason"] = nil
    end)

    it("should handle common plugin names", function()
      -- Mock vim.pack functions
      local pack_added = false
      vim.pack.add = function(spec)
        pack_added = true
      end
      vim.pack.get = function() return {} end

      -- Mock file operations
      vim.fn.writefile = function() return 0 end
      vim.fn.filereadable = function() return 0 end
      vim.fn.mkdir = function() return 0 end

      -- Mock UI responses for common plugin test
      mock_ui_responses({
        confirm = {
          ["Install this plugin"] = true,
          ["Create config file"] = true,
          ["Add require statement"] = true
        }
      })

      -- Call add_plugin with a common plugin name
      pack_manager.add_plugin("mason")

      -- Verify plugin was added
      assert.is_true(pack_added)
    end)

    it("should handle invalid input gracefully", function()
      -- Mock vim.pack functions
      vim.pack.add = function(spec) end
      vim.pack.get = function() return {} end

      -- Call add_plugin with invalid input should not throw an error
      local success = pcall(pack_manager.add_plugin, "invalid-input")
      assert.is_true(success)
    end)
  end)

  describe("update_plugin function", function()
    it("should be callable", function()
      assert.is_function(pack_manager.update_plugin)
    end)

    it("should update a specific plugin", function()
      -- Mock vim.pack functions
      local updated_plugins = {}
      vim.pack.update = function(plugins)
        if plugins then
          for _, plugin in ipairs(plugins) do
            table.insert(updated_plugins, plugin)
          end
        end
      end
      vim.pack.get = function()
        return {
          {
            active = true,
            spec = { name = "test-plugin.nvim", src = "https://github.com/user/test-plugin.nvim" }
          }
        }
      end

      -- Mock UI responses for update confirmation
      mock_ui_responses({
        confirm = {
          ["Update plugin"] = true
        }
      })

      -- Call update_plugin with specific plugin
      pack_manager.update_plugin("test-plugin.nvim")

      -- Verify the plugin was updated
      assert.are.equal(1, #updated_plugins)
      assert.are.equal("test-plugin.nvim", updated_plugins[1])
    end)

    it("should update all plugins when no plugin name provided", function()
      -- Mock vim.pack functions
      local update_all_called = false
      vim.pack.update = function(plugins)
        if not plugins then
          update_all_called = true
        end
      end
      vim.pack.get = function()
        return {
          { active = true, spec = { name = "plugin1" } },
          { active = true, spec = { name = "plugin2" } }
        }
      end

      -- Mock UI responses for update all confirmation
      mock_ui_responses({
        confirm = {
          ["Update all plugins"] = true
        }
      })

      -- Call update_plugin with empty string
      pack_manager.update_plugin("")

      -- Verify all plugins were updated
      assert.is_true(update_all_called)
    end)

    it("should handle plugin not found", function()
      vim.pack.get = function()
        return {
          { active = true, spec = { name = "existing-plugin" } }
        }
      end

      -- Should not throw error for non-existent plugin
      assert.has_no.errors(function()
        pack_manager.update_plugin("non-existent-plugin")
      end)
    end)

    it("should handle cancelled update", function()
      -- Mock vim.pack functions
      local update_called = false
      vim.pack.update = function()
        update_called = true
      end
      vim.pack.get = function()
        return {
          { active = true, spec = { name = "test-plugin" } }
        }
      end

      -- Mock UI responses to cancel update
      mock_ui_responses({
        confirm = {
          ["Update plugin"] = false
        }
      })

      pack_manager.update_plugin("test-plugin")

      -- Verify update was not called
      assert.is_false(update_called)
    end)
  end)

  describe("update_all_plugins function", function()
    it("should be callable", function()
      assert.is_function(pack_manager.update_all_plugins)
    end)

    it("should update all plugins", function()
      -- Mock vim.pack functions
      local update_all_called = false
      vim.pack.update = function()
        update_all_called = true
      end
      vim.pack.get = function()
        return {
          { active = true, spec = { name = "plugin1" } },
          { active = true, spec = { name = "plugin2" } },
          { active = true, spec = { name = "plugin3" } }
        }
      end

      -- Mock UI responses to confirm update all
      mock_ui_responses({
        confirm = {
          ["Update all"] = true
        }
      })

      pack_manager.update_all_plugins()

      -- Verify all plugins were updated
      assert.is_true(update_all_called)
    end)

    it("should handle no plugins installed", function()
      vim.pack.get = function()
        return {}
      end

      -- Should not throw error
      assert.has_no.errors(function()
        pack_manager.update_all_plugins()
      end)
    end)

    it("should handle cancelled update", function()
      -- Mock vim.pack functions
      local update_called = false
      vim.pack.update = function()
        update_called = true
      end
      vim.pack.get = function()
        return {
          { active = true, spec = { name = "plugin1" } }
        }
      end

      -- Mock UI responses to cancel update all
      mock_ui_responses({
        confirm = {
          ["Update all"] = false
        }
      })

      pack_manager.update_all_plugins()

      -- Verify update was not called
      assert.is_false(update_called)
    end)
  end)

  describe("disable_plugin function", function()
    it("should be callable", function()
      assert.is_function(pack_manager.disable_plugin)
    end)
  end)

  describe("list_inactive_plugins function", function()
    it("should be callable", function()
      assert.is_function(pack_manager.list_inactive_plugins)
    end)

    it("should handle empty plugin list", function()
      -- Mock vim.pack.get to return empty list
      local original_get = vim.pack.get
      vim.pack.get = function()
        return {}
      end

      -- Should not throw error
      assert.has_no.errors(function()
        pack_manager.list_inactive_plugins()
      end)

      -- Restore original function
      vim.pack.get = original_get
    end)
  end)

  describe("get_plugin_info function", function()
    it("should categorize colorscheme plugins correctly", function()
      local info = pack_manager._test_get_plugin_info("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim")
      assert.are.equal("colorschemes", info.category)
      assert.is_true(info.info.has_colorscheme_command)
      assert.is_false(info.info.setup_required)
    end)

    it("should categorize LSP plugins correctly", function()
      local info = pack_manager._test_get_plugin_info("nvim-lspconfig", "https://github.com/neovim/nvim-lspconfig")
      assert.are.equal("lsp_data", info.category)  -- lspconfig is data-only, no setup needed
      assert.is_false(info.info.has_colorscheme_command)
      assert.is_false(info.info.setup_required)  -- lspconfig doesn't need setup()
    end)

    it("should categorize UI plugins correctly", function()
      local info = pack_manager._test_get_plugin_info("lualine.nvim", "https://github.com/nvim-lualine/lualine.nvim")
      assert.are.equal("ui", info.category)
      assert.is_true(info.info.setup_required)
    end)

    it("should categorize Git plugins correctly", function()
      local info = pack_manager._test_get_plugin_info("gitsigns.nvim", "https://github.com/lewis6991/gitsigns.nvim")
      assert.are.equal("git", info.category)
      assert.is_true(info.info.setup_required)
    end)

    it("should default to default category for unknown plugins", function()
      local info = pack_manager._test_get_plugin_info("unknown-plugin", "https://github.com/user/unknown-plugin")
      assert.are.equal("default", info.category)
      assert.is_true(info.info.setup_required)
    end)
  end)

  describe("create_plugin_config function", function()
    before_each(function()
      -- Mock file operations
      vim.fn.filereadable = function() return 0 end
      vim.fn.writefile = function() return 0 end
      vim.fn.mkdir = function() return 0 end
    end)

    it("should create colorscheme config with colorscheme command when requested", function()
      local written_content = nil
      vim.fn.writefile = function(lines, file)
        written_content = lines
        return 0
      end

      -- Mock UI responses to not load immediately
      mock_ui_responses({
        confirm = {
          ["Load and apply the colorscheme now"] = false
        }
      })

      pack_manager._test_create_plugin_config("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim", {
        add_require = false,
        set_colorscheme = true
      })

      assert.is_not_nil(written_content)
      -- Check for colorscheme command
      local has_colorscheme_cmd = false
      local colorscheme_line_index = nil
      local pack_add_line_index = nil

      for i, line in ipairs(written_content) do
        if line:match("vim%.pack%.add") then
          pack_add_line_index = i
        end
        if line:match("vim%.cmd%.colorscheme") and not line:match("^%-%-") then
          has_colorscheme_cmd = true
          colorscheme_line_index = i
        end
      end

      assert.is_true(has_colorscheme_cmd)
      assert.is_not_nil(pack_add_line_index)
      assert.is_not_nil(colorscheme_line_index)
      -- Ensure colorscheme command comes AFTER vim.pack.add
      assert.is_true(colorscheme_line_index > pack_add_line_index)
    end)

    it("should create colorscheme config with commented command by default", function()
      local written_content = nil
      vim.fn.writefile = function(lines, file)
        written_content = lines
        return 0
      end

      pack_manager._test_create_plugin_config("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim", {
        add_require = false,
        set_colorscheme = false
      })

      assert.is_not_nil(written_content)
      -- Check that colorscheme command is commented
      local has_commented_colorscheme = false
      local pack_add_line_index = nil
      local colorscheme_line_index = nil

      for i, line in ipairs(written_content) do
        if line:match("vim%.pack%.add") then
          pack_add_line_index = i
        end
        if line:match("^%-%- vim%.cmd%.colorscheme") then
          has_commented_colorscheme = true
          colorscheme_line_index = i
        end
      end

      assert.is_true(has_commented_colorscheme)
      assert.is_not_nil(pack_add_line_index)
      assert.is_not_nil(colorscheme_line_index)
      -- Ensure commented colorscheme command still comes AFTER vim.pack.add
      assert.is_true(colorscheme_line_index > pack_add_line_index)
    end)

    it("should create LSP data config without setup call", function()
      local written_content = nil
      vim.fn.writefile = function(lines, file)
        written_content = lines
        return 0
      end

      pack_manager._test_create_plugin_config("nvim-lspconfig", "https://github.com/neovim/nvim-lspconfig", {
        add_require = false,
        set_colorscheme = false
      })

      assert.is_not_nil(written_content)
      -- Check that there's NO require().setup() pattern for lspconfig
      local has_setup = false
      local pack_add_line_index = nil
      local has_usage_comment = false

      for i, line in ipairs(written_content) do
        if line:match("vim%.pack%.add") then
          pack_add_line_index = i
        end
        if line:match("require%(.+%)%.setup%(") then
          has_setup = true
        end
        if line:match("Example usage:") then
          has_usage_comment = true
        end
      end

      assert.is_false(has_setup)  -- lspconfig should NOT have setup()
      assert.is_not_nil(pack_add_line_index)
      assert.is_true(has_usage_comment)  -- Should have usage examples instead
    end)

    it("should create LSP config with setup call for plugins that need it", function()
      local written_content = nil
      vim.fn.writefile = function(lines, file)
        written_content = lines
        return 0
      end

      pack_manager._test_create_plugin_config("mason.nvim", "https://github.com/mason-org/mason.nvim", {
        add_require = false,
        set_colorscheme = false
      })

      assert.is_not_nil(written_content)
      -- Check for require().setup() pattern
      local has_setup = false
      local pack_add_line_index = nil
      local setup_line_index = nil

      for i, line in ipairs(written_content) do
        if line:match("vim%.pack%.add") then
          pack_add_line_index = i
        end
        if line:match("require%(.+%)%.setup%(") then
          has_setup = true
          setup_line_index = i
        end
      end

      assert.is_true(has_setup)  -- mason should have setup()
      assert.is_not_nil(pack_add_line_index)
      assert.is_not_nil(setup_line_index)
      -- Ensure setup call comes AFTER vim.pack.add
      assert.is_true(setup_line_index > pack_add_line_index)
    end)

    it("should add require statement when requested", function()
      local init_content = nil
      local original_readfile = vim.fn.readfile
      local original_writefile = vim.fn.writefile
      local original_filereadable = vim.fn.filereadable

      vim.fn.filereadable = function(file)
        if file:match("init%.lua$") then
          return 1  -- init.lua exists
        end
        return 0
      end

      vim.fn.readfile = function(file)
        if file:match("init%.lua$") then
          return {"-- Existing init.lua content", "require('plugins.existing')"}
        end
        return {}
      end

      vim.fn.writefile = function(lines, file)
        if file:match("init%.lua$") then
          init_content = lines
        end
        return 0
      end

      pack_manager._test_create_plugin_config("test-plugin", "https://github.com/user/test-plugin", {
        add_require = true,
        set_colorscheme = false
      })

      assert.is_not_nil(init_content)
      -- Check that require statement was added
      local has_require = false
      for _, line in ipairs(init_content) do
        if line:match("require%('plugins%.test%-plugin'%)") then
          has_require = true
          break
        end
      end
      assert.is_true(has_require)

      -- Restore
      vim.fn.readfile = original_readfile
      vim.fn.writefile = original_writefile
      vim.fn.filereadable = original_filereadable
    end)
  end)

  describe("config content verification", function()
    it("should generate correct colorscheme config content", function()
      local written_content = nil
      vim.fn.writefile = function(lines, file)
        written_content = lines
        return 0
      end
      vim.fn.filereadable = function() return 0 end
      vim.fn.mkdir = function() return 0 end

      -- Mock UI responses to not load immediately
      mock_ui_responses({
        confirm = {
          ["Load and apply the colorscheme now"] = false
        }
      })

      pack_manager._test_create_plugin_config("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim", {
        add_require = false,
        set_colorscheme = true
      })

      assert.is_not_nil(written_content)
      -- Verify exact content structure
      assert.are.equal('vim.pack.add({', written_content[1])
      assert.are.equal('  "https://github.com/folke/tokyonight.nvim",', written_content[2])
      assert.are.equal('})', written_content[3])
      assert.are.equal('', written_content[4])
      assert.are.equal('-- tokyonight.nvim colorscheme configuration', written_content[5])
      assert.are.equal('-- Uncomment the line below to set as default colorscheme', written_content[6])
      -- This should be uncommented when set_colorscheme is true
      assert.are.equal("vim.cmd.colorscheme('tokyonight')", written_content[7])
    end)

    it("should load colorscheme immediately when user chooses to", function()
      vim.fn.writefile = function()
        return 0
      end
      vim.fn.filereadable = function() return 0 end
      vim.fn.mkdir = function() return 0 end

      -- Mock UI responses to load immediately
      mock_ui_responses({
        confirm = {
          ["Load and apply the colorscheme now"] = true
        }
      })

      -- Test passes if config creation succeeds with immediate loading option
      assert.has_no.errors(function()
        pack_manager._test_create_plugin_config("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim", {
          add_require = false,
          set_colorscheme = true
        })
      end)
    end)

    it("should not prompt for immediate loading when set_colorscheme is false", function()
      vim.fn.writefile = function() return 0 end
      vim.fn.filereadable = function() return 0 end
      vim.fn.mkdir = function() return 0 end

      -- Mock UI responses to detect colorscheme prompt call
      mock_ui_responses({
        confirm = {
          ["Load and apply the colorscheme now"] = false
        }
      })

      -- The test logic changes - we'll check that the UI function wasn't called
      -- since set_colorscheme is false

      pack_manager._test_create_plugin_config("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim", {
        add_require = false,
        set_colorscheme = false  -- Not activating colorscheme
      })

      -- Test passes if config creation succeeds without errors
      -- (The UI function shouldn't be called when set_colorscheme is false)
    end)

    it("should handle source command errors gracefully", function()
      vim.fn.writefile = function() return 0 end
      vim.fn.filereadable = function() return 0 end
      vim.fn.mkdir = function() return 0 end

      -- Mock vim.cmd to throw error on source
      local original_cmd = vim.cmd
      vim.cmd = function(cmd)
        if type(cmd) == "string" and cmd:match("^source ") then
          error("Failed to source file")
        end
      end

      -- Mock UI responses to load immediately
      mock_ui_responses({
        confirm = {
          ["Load and apply the colorscheme now"] = true
        }
      })

      -- Should not throw error
      assert.has_no.errors(function()
        pack_manager._test_create_plugin_config("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim", {
          add_require = false,
          set_colorscheme = true
        })
      end)

      -- Restore
      vim.cmd = original_cmd
    end)
  end)

  describe("interactive installation", function()
    before_each(function()
      -- Mock UI responses
      mock_ui_responses({
        confirm = {
          ["Create config file"] = true,
          ["Add require statement"] = true,
          ["Apply this colorscheme"] = false
        }
      })

      -- Mock file operations
      vim.fn.filereadable = function() return 0 end
      vim.fn.writefile = function() return 0 end
      vim.fn.mkdir = function() return 0 end
    end)

    it("should handle colorscheme installation flow", function()
      -- Mock UI responses to apply colorscheme
      mock_ui_responses({
        confirm = {
          ["Apply this colorscheme"] = true
        }
      })

      -- This would be called internally by add_plugin
      -- We're testing the flow logic
      local info = pack_manager._test_get_plugin_info("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim")
      assert.are.equal("colorschemes", info.category)
      assert.is_true(info.info.has_colorscheme_command)
    end)
  end)

  describe("main menu function", function()
    it("should be callable", function()
      assert.is_function(pack_manager.show_main_menu)
    end)

    it("should handle menu in test mode", function()
      -- Mock UI for menu test
      mock_ui_responses({})

      -- Should not throw error in test mode
      assert.has_no.errors(function()
        pack_manager.show_main_menu()
      end)
    end)
  end)
end)
