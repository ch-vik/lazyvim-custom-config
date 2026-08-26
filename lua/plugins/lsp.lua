return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          -- Root detection comes from nvim-lspconfig's own `root_markers`, which
          -- already prefers pyrightconfig.json and falls back to .git.
          settings = {
            python = {
              analysis = {
                -- your existing analysis settings
              },
            },
          },
        },
      },
    },
  },
}
