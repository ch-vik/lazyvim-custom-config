return {
  "nvim-neotest/neotest",
  keys = {
    {
      "<leader>dtd",
      function()
        require("neotest").run.run({ strategy = "dap" })
      end,
      desc = "Run test with DAP",
    },
    {
      "<leader>dtt",
      function()
        require("neotest").run.run()
      end,
      desc = "Run nearest test",
    },
  },
  opts = function(_, opts)
    opts.adapters = opts.adapters or {}
    vim.list_extend(opts.adapters, {
      require("rustaceanvim.neotest"),
    })
  end,
}
