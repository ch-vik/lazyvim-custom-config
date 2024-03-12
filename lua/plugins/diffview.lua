return {
  "sindrets/diffview.nvim",
  lazy = false,
  keys = {
    { "<leader>gd", "<cmd>DiffviewFileHistory %<cr>", desc = "Git current file history" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
  },
}
