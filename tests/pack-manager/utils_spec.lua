-- Tests for pack-manager utility functions

require('tests.minimal_init')

describe("pack-manager utils", function()
  local utils

  before_each(function()
    -- Reset the module cache
    package.loaded['pack-manager.utils'] = nil

    -- Load the utils module
    utils = require('pack-manager.utils')
  end)

  describe("normalize_plugin_name", function()
    it("should remove .nvim suffix", function()
      assert.are.equal("tokyonight", utils.normalize_plugin_name("tokyonight.nvim"))
      assert.are.equal("gitsigns", utils.normalize_plugin_name("gitsigns.nvim"))
    end)

    it("should remove .vim suffix", function()
      assert.are.equal("vim-fugitive", utils.normalize_plugin_name("vim-fugitive.vim"))
    end)

    it("should remove .lua suffix", function()
      assert.are.equal("plenary", utils.normalize_plugin_name("plenary.lua"))
    end)

    it("should leave names without suffixes unchanged", function()
      assert.are.equal("telescope", utils.normalize_plugin_name("telescope"))
      assert.are.equal("mason", utils.normalize_plugin_name("mason"))
    end)

    it("should handle complex names", function()
      assert.are.equal("nvim-lspconfig", utils.normalize_plugin_name("nvim-lspconfig"))
      assert.are.equal("nvim-web-devicons", utils.normalize_plugin_name("nvim-web-devicons.nvim"))
    end)
  end)

  describe("parse_plugin_spec", function()
    it("should parse GitHub shorthand correctly", function()
      local result, err = utils.parse_plugin_spec("folke/tokyonight.nvim")

      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.are.equal("https://github.com/folke/tokyonight.nvim.git", result.url)
      assert.are.equal("tokyonight.nvim", result.name)
      assert.are.equal("main", result.version)
    end)

    it("should parse full HTTPS URLs", function()
      local result, err = utils.parse_plugin_spec("https://github.com/neovim/nvim-lspconfig.git")

      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.are.equal("https://github.com/neovim/nvim-lspconfig.git", result.url)
      assert.are.equal("nvim-lspconfig", result.name)
    end)

    it("should parse full HTTPS URLs without .git", function()
      local result, err = utils.parse_plugin_spec("https://github.com/lewis6991/gitsigns.nvim")

      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.are.equal("https://github.com/lewis6991/gitsigns.nvim", result.url)
      assert.are.equal("gitsigns.nvim", result.name)
    end)

    it("should reject invalid specifications", function()
      local result, err = utils.parse_plugin_spec("invalid-spec")

      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.are.equal("Invalid plugin specification. Use 'owner/repo' or full URL.", err)
    end)

    it("should handle edge cases", function()
      local result, err = utils.parse_plugin_spec("user/repo-with-dashes")

      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.are.equal("repo-with-dashes", result.name)
    end)

    it("should use correct default branch for telescope", function()
      local result, err = utils.parse_plugin_spec("nvim-telescope/telescope.nvim")

      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.are.equal("telescope.nvim", result.name)
      assert.are.equal("master", result.version)
    end)

    it("should use main branch for other plugins", function()
      local result, err = utils.parse_plugin_spec("folke/tokyonight.nvim")

      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.are.equal("tokyonight.nvim", result.name)
      assert.are.equal("main", result.version)
    end)
  end)

  describe("validate_plugin_name", function()
    it("should accept valid plugin names", function()
      local valid, err = utils.validate_plugin_name("telescope")
      assert.is_true(valid)
      assert.is_nil(err)

      valid, err = utils.validate_plugin_name("nvim-lspconfig")
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should reject empty names", function()
      local valid, err = utils.validate_plugin_name("")
      assert.is_false(valid)
      assert.are.equal("Plugin name cannot be empty", err)

      valid, err = utils.validate_plugin_name(nil)
      assert.is_false(valid)
      assert.are.equal("Plugin name cannot be empty", err)
    end)

    it("should reject whitespace-only names", function()
      local valid, err = utils.validate_plugin_name("   ")
      assert.is_false(valid)
      assert.are.equal("Plugin name cannot be only whitespace", err)
    end)
  end)

  describe("get_plugin_config_path", function()
    it("should generate correct config paths", function()
      local path = utils.get_plugin_config_path("tokyonight.nvim")
      assert.is_true(path:match("/lua/plugins/tokyonight%.lua$") ~= nil)

      path = utils.get_plugin_config_path("telescope")
      assert.is_true(path:match("/lua/plugins/telescope%.lua$") ~= nil)
    end)
  end)

  describe("get_disabled_config_path", function()
    it("should generate correct disabled config paths", function()
      local path = utils.get_disabled_config_path("gitsigns.nvim")
      assert.is_true(path:match("/lua/plugins/disabled/gitsigns%.lua$") ~= nil)
    end)
  end)

  describe("path getters", function()
    it("should return proper base directories", function()
      local config_dir = utils.get_config_dir()
      assert.is_string(config_dir)
      assert.is_true(config_dir:len() > 0)

      local plugins_dir = utils.get_plugins_dir()
      assert.is_true(plugins_dir:match("/lua/plugins$") ~= nil)

      local disabled_dir = utils.get_disabled_dir()
      assert.is_true(disabled_dir:match("/lua/plugins/disabled$") ~= nil)

      local init_file = utils.get_init_file()
      assert.is_true(init_file:match("/init%.lua$") ~= nil)
    end)
  end)

  describe("is_plugin_installed", function()
    it("should detect installed plugins", function()
      -- Mock vim.pack.get to return some plugins
      local original_get = vim.pack.get
      vim.pack.get = function()
        return {
          {
            active = true,
            path = "/some/path",
            spec = {
              name = "telescope.nvim",
              src = "https://github.com/nvim-telescope/telescope.nvim.git"
            }
          }
        }
      end

      local installed, plugin = utils.is_plugin_installed("telescope.nvim")
      assert.is_true(installed)
      assert.is_not_nil(plugin)

      installed, plugin = utils.is_plugin_installed("nonexistent")
      assert.is_false(installed)
      assert.is_nil(plugin)

      -- Restore original function
      vim.pack.get = original_get
    end)
  end)

  describe("get_inactive_plugins", function()
    it("should return list of inactive plugins", function()
      -- Mock vim.pack.get to return some plugins
      local original_get = vim.pack.get
      vim.pack.get = function()
        return {
          {
            active = true,
            spec = { name = "active-plugin" }
          },
          {
            active = false,
            spec = { name = "inactive-plugin" }
          }
        }
      end

      local inactive = utils.get_inactive_plugins()
      assert.are.equal(1, #inactive)
      assert.are.equal("inactive-plugin", inactive[1])

      -- Restore original function
      vim.pack.get = original_get
    end)
  end)
end)
