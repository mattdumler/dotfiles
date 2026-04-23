return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Trouble: Diagnostics" },
      { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Trouble: Buffer diagnostics" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Trouble: Loclist" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Trouble: Quickfix" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Trouble: Symbols" },
    },
  },
}
