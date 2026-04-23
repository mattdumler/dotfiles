return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        opts = {
          ensure_installed = { "clangd", "clang-format", "codelldb" },
          run_on_start = true,
          auto_update = false,
        },
      },
      { "p00f/clangd_extensions.nvim", lazy = true },
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink and blink.get_lsp_capabilities then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●" },
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        underline = true,
        update_in_insert = false,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local function bmap(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          bmap("n", "gd", vim.lsp.buf.definition, "LSP: Definition")
          bmap("n", "gy", vim.lsp.buf.type_definition, "LSP: Type definition")
          bmap("n", "gi", vim.lsp.buf.implementation, "LSP: Implementation")
          bmap("n", "gr", function() require("telescope.builtin").lsp_references() end, "LSP: References")
          bmap("n", "K", vim.lsp.buf.hover, "LSP: Hover")
          bmap("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
          bmap({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, "LSP: Code action")
          bmap("n", "[d", vim.diagnostic.goto_prev, "Diagnostic: Prev")
          bmap("n", "]d", vim.diagnostic.goto_next, "Diagnostic: Next")

          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            bmap("n", "<leader>ih", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, "LSP: Toggle inlay hints")
          end

          if client and client.name == "clangd" then
            bmap("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>", "C++: Switch source/header")
          end
        end,
      })

      -- clangd_extensions registers :ClangdSwitchSourceHeader and friends.
      require("clangd_extensions").setup({
        inlay_hints = { inline = false },
      })

      -- Configure + enable clangd via nvim 0.11+ native API.
      -- nvim-lspconfig ships `lsp/clangd.lua` with sane defaults (filetypes, etc.);
      -- this call extends it with our cmd/capabilities/root_markers.
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--compile-commands-dir=build",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
          "--pch-storage=memory",
          "--all-scopes-completion",
          "-j=8",
        },
        capabilities = capabilities,
        root_markers = { "compile_commands.json", ".clangd", ".clang-format", "CMakeLists.txt", ".git" },
      })
      vim.lsp.enable("clangd")
    end,
  },
}
