-- Neovim configuration
-- Copyright (c) 2025 Matt Dumler
-- MIT license

-- Leader must be set before lazy loads so lazy-mapped keys see it.
vim.g.mapleader = ","
vim.g.maplocalleader = ","

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
