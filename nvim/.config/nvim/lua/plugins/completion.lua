return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = (not jit.os:find("Windows")) and "make install_jsregexp" or nil,
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    opts = {
      keymap = {
        preset = "default",
        ["<C-l>"] = {
          "select_and_accept",
          function()
            local ok, ls = pcall(require, "luasnip")
            if ok and ls.expandable() then
              ls.expand()
              return true
            end
          end,
          "snippet_forward",
          "fallback",
        },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 250 },
        ghost_text = { enabled = false },
      },
      snippets = { preset = "luasnip" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
  },
}
