local map = vim.keymap.set

-- Buffer navigation
map("n", "<C-n>", ":bnext!<CR>", { silent = true, desc = "Next buffer" })
map("n", "<C-p>", ":bprevious!<CR>", { silent = true, desc = "Previous buffer" })
map("n", "<C-x>", ":bdelete<CR>", { silent = true, desc = "Delete buffer" })

-- Pane navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
