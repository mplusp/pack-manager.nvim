-- Luacheck configuration for pack-manager.nvim

-- Ignore warnings about vim global
globals = {
  "vim",
}

-- Standard library
std = "lua51"

-- Ignore some common patterns
ignore = {
  "212", -- Unused argument
  "213", -- Unused loop variable
  "631", -- Line too long
}

-- Files to exclude
exclude_files = {
  ".luarocks/",
  "tests/minimal_init.lua", -- Contains lots of mocking
}

-- Read globals from files
read_globals = {
  "vim",
  "describe",
  "it",
  "before_each",
  "after_each",
  "setup",
  "teardown",
  "assert",
  "spy",
  "stub",
  "mock",
}

-- Test files have additional globals
files["tests/**/*.lua"] = {
  read_globals = {
    "describe",
    "it", 
    "before_each",
    "after_each",
    "setup",
    "teardown",
    "assert",
    "spy",
    "stub",
    "mock",
  }
}