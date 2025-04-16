return {
  "akinsho/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
  },
  ---@class flutter.ProjectConfig
  opts = {
    debugger = {
      enabled = true,
      run_via_dap = true,
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
        require("dap.ext.vscode").load_launchjs()
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
    experimental = {
      lsp_derive_paths = true,
      multi_root = true,
    },
    root_patterns = { "melos.yaml, .git" },
  },
}
