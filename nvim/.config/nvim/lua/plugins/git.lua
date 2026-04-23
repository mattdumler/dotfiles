return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function bmap(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        bmap("n", "]c", function() gs.nav_hunk("next") end, "Next hunk")
        bmap("n", "[c", function() gs.nav_hunk("prev") end, "Prev hunk")
        bmap("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        bmap("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        bmap("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        bmap("n", "<leader>hd", gs.diffthis, "Diff this")
        bmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        bmap("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
      end,
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = { "G", "Git", "Gdiffsplit", "Gread", "Gwrite", "Gedit", "Gclog" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
    },
  },
}
