local opt = vim.opt

-- Visual indicators
opt.showmode = true
opt.wildmenu = true
opt.wildmode = { "longest", "full" }
opt.cursorline = true
opt.number = true
opt.ruler = true
opt.scrolloff = 5
opt.wrap = false
opt.termguicolors = true
opt.signcolumn = "yes"

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Tabs/indent
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Folding via treesitter
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false

-- Spell
opt.spelllang = { "en_us" }
opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

-- QoL
opt.updatetime = 250
opt.timeoutlen = 400
opt.undofile = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- Disable unused remote-plugin providers. Nothing in this config uses them and
-- leaving them on produces noisy :checkhealth warnings about missing pip/gem/etc.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
