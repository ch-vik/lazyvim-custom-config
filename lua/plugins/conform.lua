return {
  "stevearc/conform.nvim",
  opts = {
    ---@type table<string, conform.FormatterUnit[]>
    formatters_by_ft = {
      sql = { "sql_formatter" },
    },
    formatters = {
      sql_formatter = {
        args = {
          "-l",
          "postgresql",
        },
      },
    },
  },
}
