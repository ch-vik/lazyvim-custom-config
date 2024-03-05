return {
  "mason.nvim",
  ---@class MasonSettings
  opts = {
    ensure_installed = {
      "gopls",
      "stylua",
      "shfmt",
      "goimports",
      "gofumpt",
    },
  },
}
