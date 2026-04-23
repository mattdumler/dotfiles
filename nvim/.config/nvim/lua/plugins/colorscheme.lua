return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha",
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = true,
        neotree = true,
        treesitter = true,
        telescope = { enabled = true },
        which_key = true,
        native_lsp = { enabled = true },
        dap = true,
        dap_ui = true,
        fidget = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
