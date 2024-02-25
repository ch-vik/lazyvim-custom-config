return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    {
      "<C-n>",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = require("lazyvim.util").root() })
      end,
      desc = "Explorer NeoTree (root dir)",
    },
  },
}
