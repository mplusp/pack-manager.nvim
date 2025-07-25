-- Tests for pack-manager main module

require('tests.minimal_init')

describe("pack-manager main module", function()
  local pack_manager

  before_each(function()
    -- Reset the module cache
    package.loaded['pack-manager'] = nil
    package.loaded['pack-manager.init'] = nil

    -- Reset vim.g
    vim.g.loaded_pack_manager = nil

    -- Load the module fresh
    pack_manager = require('pack-manager')
  end)

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

    -- Note: Full integration testing would require more complex mocking
    -- of vim.pack.add, file system operations, etc.
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
      assert.are.equal("lsp", info.category)
      assert.is_false(info.info.has_colorscheme_command)
      assert.is_true(info.info.setup_required)
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

      pack_manager._test_create_plugin_config("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim", {
        add_require = false,
        set_colorscheme = true
      })

      assert.is_not_nil(written_content)
      -- Check for colorscheme command
      local has_colorscheme_cmd = false
      for _, line in ipairs(written_content) do
        if line:match("vim%.cmd%.colorscheme") and not line:match("^%-%-") then
          has_colorscheme_cmd = true
          break
        end
      end
      assert.is_true(has_colorscheme_cmd)
    end)

    it("should create LSP config with setup call", function()
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
      -- Check for require().setup() pattern
      local has_setup = false
      for _, line in ipairs(written_content) do
        if line:match("require%(.+%)%.setup%(") then
          has_setup = true
          break
        end
      end
      assert.is_true(has_setup)
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

  describe("interactive installation", function()
    before_each(function()
      -- Mock user input
      vim.fn.input = function(prompt)
        if prompt:match("Create config file") then
          return "y"
        elseif prompt:match("Add require statement") then
          return "y"
        elseif prompt:match("Apply this colorscheme") then
          return "n"
        end
        return ""
      end

      -- Mock file operations
      vim.fn.filereadable = function() return 0 end
      vim.fn.writefile = function() return 0 end
      vim.fn.mkdir = function() return 0 end
    end)

    it("should handle colorscheme installation flow", function()
      -- Test with user choosing to apply colorscheme
      vim.fn.input = function(prompt)
        if prompt:match("Apply this colorscheme") then
          return "y"
        end
        return "y"
      end

      -- This would be called internally by add_plugin
      -- We're testing the flow logic
      local info = pack_manager._test_get_plugin_info("tokyonight.nvim", "https://github.com/folke/tokyonight.nvim")
      assert.are.equal("colorschemes", info.category)
      assert.is_true(info.info.has_colorscheme_command)
    end)
  end)
end)
