return {
  "mason-org/mason-lspconfig.nvim",
  ---@class MasonLspconfigSettings
  opts = {
    ensure_installed = {
      "gopls",
      "biome",
      "sqlls",
    },
  },
}
