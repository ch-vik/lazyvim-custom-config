local ls = require("luasnip")

return {
  "L3MON4D3/LuaSnip",
  keys = {
    {
      mode = { "i" },
      "<Tab>",
      false,
    },
    {
      mode = { "i" },
      "<S-Tab>",
      false,
    },
    {
      mode = { "i" },
      "<C-K>",
      function()
        ls.expand()
      end,
      desc = "LuaSnip: Expand",
      silent = true,
    },
    {
      mode = { "i", "s" },
      "<C-L>",
      function()
        ls.jump(1)
      end,
      silent = true,
      desc = "LuaSnip: Next",
    },
    {
      mode = { "i", "s" },
      "<C-J>",
      function()
        ls.jump(-1)
      end,
      silent = true,
      desc = "LuaSnip: Prev",
    },
  },
}
