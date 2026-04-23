return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "jay-babu/mason-nvim-dap.nvim",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "DAP: Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "DAP: Continue" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "DAP: Step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "DAP: Step into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "DAP: Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "DAP: REPL" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP: UI" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "DAP: Terminate" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb" },
        automatic_installation = true,
        handlers = {
          function(config)
            require("mason-nvim-dap").default_setup(config)
          end,
        },
      })

      dapui.setup()

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      dap.configurations.cpp = {
        {
          name = "Launch (codelldb)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
      dap.configurations.c = dap.configurations.cpp
    end,
  },
}
