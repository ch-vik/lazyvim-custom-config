local isEnabled = true

return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "onsails/lspkind.nvim",
    },
    enabled = isEnabled,
    opts = {
      window = {
        completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          col_offset = -3,
          side_padding = 0,
        },
      },
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
          local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
          local strings = vim.split(kind.kind, "%s", { trimempty = true })
          kind.kind = " " .. (strings[1] or "") .. " "
          kind.menu = "    (" .. (strings[2] or "") .. ")"

          return kind
        end,
      },
    },
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    enabled = isEnabled,
  },
  {
    "hrsh7th/cmp-buffer",
    enabled = isEnabled,
  },
  { "hrsh7th/cmp-path", enabled = isEnabled },
}
