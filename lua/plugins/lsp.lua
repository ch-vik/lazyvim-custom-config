return {
  -- Add or modify the existing pyright configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          -- Override the root_dir function to look for pyrightconfig.json
          root_dir = function(fname)
            local util = require("lspconfig.util")
            local root_files = {
              "pyrightconfig.json",
              ".git",
              "setup.py",
              "pyproject.toml",
            }
            return util.root_pattern(unpack(root_files))(fname) or util.find_git_ancestor(fname)
          end,
          -- Keep your other pyright settings
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
