return {
  "williamboman/mason.nvim",
  ---@class MasonSettings
  opts = {
    ensure_installed = {
      "sql-formatter",
      "biome",
    },
    automatic_installation = { exclude = { "rust_analyzer" } },
  },
}
