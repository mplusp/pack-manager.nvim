-- Tests for pack-manager UI module

require('tests.minimal_init')

describe("pack-manager ui module", function()
  local ui

  before_each(function()
    -- Reset the module cache
    package.loaded['pack-manager.ui'] = nil

    -- Load the module fresh
    ui = require('pack-manager.ui')

    -- Enable test mode
    ui._test_mode = true
  end)

  describe("confirm dialog", function()
    it("should return default value in test mode", function()
      local result = ui.confirm("Test confirmation?", true)
      assert.is_true(result)

      result = ui.confirm("Test confirmation?", false)
      assert.is_false(result)
    end)

    it("should handle test responses", function()
      ui._test_responses = {
        ["Specific message"] = false
      }

      local result = ui.confirm("Specific message", true)
      assert.is_false(result)

      -- Reset test responses
      ui._test_responses = nil
    end)
  end)

  describe("select dialog", function()
    it("should return default index in test mode", function()
      local options = {"Option 1", "Option 2", "Option 3"}

      local result = ui.select("Choose option:", options, 2)
      assert.are.equal(2, result)

      result = ui.select("Choose option:", options)
      assert.are.equal(1, result) -- default to 1 if no default provided
    end)

    it("should handle empty options", function()
      local options = {}
      local result = ui.select("Choose option:", options)
      assert.are.equal(1, result)
    end)
  end)

  describe("input dialog", function()
    it("should return default text in test mode", function()
      local result = ui.input("Enter name:", "default")
      assert.are.equal("default", result)

      result = ui.input("Enter name:")
      assert.are.equal("", result)
    end)
  end)

  describe("info dialog", function()
    it("should not error in test mode", function()
      assert.has_no.errors(function()
        ui.info("Test information", "Test Title")
      end)
    end)
  end)

  describe("menu dialog", function()
    it("should return default action in test mode", function()
      local result = ui.menu()
      assert.are.equal("add", result)
    end)
  end)

  describe("key input simulation tests", function()
    before_each(function()
      -- Disable test mode for these specific tests
      ui._test_mode = false

      -- Mock vim.fn.getchar to simulate key presses
      local key_queue = {}
      local key_index = 1

      -- Store original getchar and char2nr
      _G.original_getchar = vim.fn.getchar
      _G.original_char2nr = vim.fn.char2nr

      -- Helper to set up key simulation
      _G.simulate_keys = function(keys)
        key_queue = keys
        key_index = 1
        vim.fn.getchar = function()
          if key_index <= #key_queue then
            local key = key_queue[key_index]
            key_index = key_index + 1
            return key
          end
          return 27 -- Default to escape if no more keys
        end
      end

      -- Mock char2nr to handle strings (like arrow keys)
      vim.fn.char2nr = function(str)
        if type(str) == "string" and #str > 0 then
          return string.byte(str, 1)
        end
        return 0
      end
    end)

    after_each(function()
      -- Restore original getchar and char2nr
      vim.fn.getchar = _G.original_getchar
      vim.fn.char2nr = _G.original_char2nr
      ui._test_mode = true
    end)

    describe("confirm dialog key handling", function()
      it("should handle 'y' key", function()
        _G._G.simulate_keys({string.byte('y')})
        local result = ui.confirm("Test?", false)
        assert.is_true(result)
      end)

      it("should handle 'Y' key", function()
        _G.simulate_keys({string.byte('Y')})
        local result = ui.confirm("Test?", false)
        assert.is_true(result)
      end)

      it("should handle 'n' key", function()
        _G.simulate_keys({string.byte('n')})
        local result = ui.confirm("Test?", true)
        assert.is_false(result)
      end)

      it("should handle 'N' key", function()
        _G.simulate_keys({string.byte('N')})
        local result = ui.confirm("Test?", true)
        assert.is_false(result)
      end)

      it("should handle Enter key with default", function()
        _G.simulate_keys({13}) -- Enter key
        local result = ui.confirm("Test?", true)
        assert.is_true(result)

        _G.simulate_keys({13}) -- Enter key
        result = ui.confirm("Test?", false)
        assert.is_false(result)
      end)

      it("should handle Escape key", function()
        _G.simulate_keys({27}) -- Escape
        local result = ui.confirm("Test?", true)
        assert.is_false(result)
      end)

      it("should handle 'q' key", function()
        _G.simulate_keys({string.byte('q')})
        local result = ui.confirm("Test?", true)
        assert.is_false(result)
      end)
    end)

    describe("select dialog key handling", function()
      local options = {"Option 1", "Option 2", "Option 3"}

      it("should handle number keys", function()
        _G.simulate_keys({string.byte('2')})
        local result = ui.select("Choose:", options)
        assert.are.equal(2, result)

        _G.simulate_keys({string.byte('3')})
        result = ui.select("Choose:", options)
        assert.are.equal(3, result)
      end)

      it("should handle Enter key", function()
        _G.simulate_keys({13}) -- Enter on first option
        local result = ui.select("Choose:", options)
        assert.are.equal(1, result)
      end)

      it("should handle j/k navigation", function()
        _G.simulate_keys({string.byte('j'), 13}) -- Down then Enter
        local result = ui.select("Choose:", options)
        assert.are.equal(2, result)

        _G.simulate_keys({string.byte('j'), string.byte('j'), string.byte('k'), 13}) -- Down, down, up, Enter
        result = ui.select("Choose:", options)
        assert.are.equal(2, result)
      end)

      it("should handle Escape key", function()
        _G.simulate_keys({27}) -- Escape
        local result = ui.select("Choose:", options)
        assert.is_nil(result)
      end)

      it("should handle 'q' key", function()
        _G.simulate_keys({string.byte('q')})
        local result = ui.select("Choose:", options)
        assert.is_nil(result)
      end)

      it("should ignore invalid number keys", function()
        _G.simulate_keys({string.byte('9'), 13}) -- 9 is out of range, then Enter
        local result = ui.select("Choose:", options)
        assert.are.equal(1, result) -- Should still be on first option
      end)
    end)

    describe("menu dialog key handling", function()
      it("should handle number keys 1-8", function()
        _G.simulate_keys({string.byte('1')})
        local result = ui.menu()
        assert.are.equal("add", result)

        _G.simulate_keys({string.byte('2')})
        result = ui.menu()
        assert.are.equal("list", result)

        _G.simulate_keys({string.byte('3')})
        result = ui.menu()
        assert.are.equal("update", result)

        _G.simulate_keys({string.byte('8')})
        result = ui.menu()
        assert.are.equal("info", result)
      end)

      it("should handle Escape key", function()
        _G.simulate_keys({27}) -- Escape
        local result = ui.menu()
        assert.is_nil(result)
      end)

      it("should handle 'q' key", function()
        _G.simulate_keys({string.byte('q')})
        local result = ui.menu()
        assert.is_nil(result)
      end)

      it("should ignore invalid keys", function()
        _G.simulate_keys({string.byte('9'), string.byte('q')}) -- 9 is out of range, then q
        local result = ui.menu()
        assert.is_nil(result)
      end)

      it("should handle string keys (like arrow keys) without error", function()
        -- Simulate arrow key returning a string
        _G.simulate_keys({"<Up>", string.byte('q')}) -- Arrow key as string, then q
        local result = ui.menu()
        assert.is_nil(result)
      end)
    end)

    describe("key type handling tests", function()
      it("should handle mixed key types in confirm dialog", function()
        -- Test with string key followed by number key
        _G.simulate_keys({"<Down>", string.byte('y')}) -- Arrow key as string, then y
        local result = ui.confirm("Test?", false)
        assert.is_true(result)
      end)

      it("should handle mixed key types in select dialog", function()
        local options = {"Option 1", "Option 2", "Option 3"}
        -- Test with string key followed by number key
        _G.simulate_keys({"<Left>", 13}) -- Arrow key as string, then Enter
        local result = ui.select("Choose:", options)
        assert.are.equal(1, result)
      end)
    end)
  end)
end)
