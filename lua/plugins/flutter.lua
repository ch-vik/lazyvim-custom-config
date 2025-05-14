return {
  "akinsho/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
  },
  ---@class flutter.ProjectConfig
  opts = {
    decorations = {
      statusline = {
        app_version = true,
        device = true,
        project_config = true,
      },
    },
    widget_guides = {
      enabled = true,
    },
    debugger = {
      enabled = true,
      register_configurations = function()
        require("dap").configurations.dart = {
          {
            type = "dart",
            request = "launch",
            name = "xFarm Dev",
            program = "${workspaceFolder}/packages/xfarm/main.dart",
            args = { "--flavor", "dev" },
          },
        }
        require("dap").adapters.dart = {
          --args = { "flutter" },
          --command = "/home/kevin/.local/share/nvim/mason/bin/dart-debug-adapter",
          args = { "debug_adapter" },
          command = "/opt/flutter/bin/flutter",
          type = "executable",
        }
      end,
    },
    dev_log = {
      enabled = false,
    },
    lsp = {
      settings = {
        documentation = "full",
        analyzeAllWorkspacePackagesDependencies = true,
        completeFunctionCalls = true,
        enableSnippets = true,
        updateImportsOnRename = true,
      },
    },
    root_patterns = { "melos.yaml, .git" },
  },
}
