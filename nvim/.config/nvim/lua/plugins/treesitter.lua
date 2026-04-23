return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- The `main` branch is a ground-up rewrite with a different API; pin to the
    -- stable `master` branch for the classic `configs.setup` interface.
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "c", "cpp", "cmake", "lua", "bash",
        "markdown", "markdown_inline", "json", "yaml",
        "vim", "vimdoc", "query", "diff",
      },
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          node_decremental = "<bs>",
        },
      },
    },
  },
}
