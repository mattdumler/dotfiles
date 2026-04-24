local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
  group = augroup("YankHighlight", { clear = true }),
  callback = function() vim.highlight.on_yank({ timeout = 150 }) end,
})

autocmd("FileType", {
  group = augroup("Spell", { clear = true }),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function() vim.opt_local.spell = true end,
})
