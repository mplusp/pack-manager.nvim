#!/bin/bash

# Test runner script for pack-manager.nvim

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Running pack-manager.nvim tests${NC}"

# Check if busted is installed
if ! command -v busted &> /dev/null; then
    echo -e "${YELLOW}Warning: busted not found. Installing...${NC}"
    if command -v luarocks &> /dev/null; then
        luarocks install busted
    else
        echo -e "${RED}Error: luarocks not found. Please install luarocks first.${NC}"
        echo "On macOS: brew install luarocks"
        echo "On Ubuntu: sudo apt-get install luarocks"
        exit 1
    fi
fi

# Run the tests
echo -e "${GREEN}Running unit tests...${NC}"
cd "$(dirname "$0")/.."

if busted --verbose tests/; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi

# Run luacheck if available
if command -v luacheck &> /dev/null; then
    echo -e "${GREEN}Running linter...${NC}"
    if luacheck lua/ tests/ --globals vim; then
        echo -e "${GREEN}✅ Linting passed!${NC}"
    else
        echo -e "${YELLOW}⚠️  Linting issues found${NC}"
        # Don't fail on linting issues, just warn
    fi
else
    echo -e "${YELLOW}Warning: luacheck not found. Skipping linting.${NC}"
    echo "Install with: luarocks install luacheck"
fi

echo -e "${GREEN}🎉 Test run complete!${NC}"