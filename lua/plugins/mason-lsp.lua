return {
  "williamboman/mason-lspconfig.nvim",
  ---@class MasonLspconfigSettings
  opts = {
    ensure_installed = {
      "gopls",
      "stylua",
      "shfmt",
      "goimports",
      "gofumpt",
      "biome",
    },
  },
}
