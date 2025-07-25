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
end)
