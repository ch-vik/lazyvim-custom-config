-- LazyVim plugin specification that sets up nvim-dap for the xfarm-server Grails
-- application.  Copy this file into `~/.config/nvim/lua/plugins/` (or the
-- equivalent LazyVim plugins folder) and Lazy.nvim will load it automatically.
--
-- The definition mirrors the style requested by the user: it returns a table
-- with `lazy`, `dependencies`, `opts` and a `config` callback.  The adapter
-- attaches to a JVM that was started with the classic remote-debug parameters
-- (`-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005`) –
-- you get those automatically from Gradle via `./gradlew bootRun --debug-jvm`.
--
return {
  "mfussenegger/nvim-dap",
  lazy = false, -- load immediately so the configuration is registered at startup

  ---@class xfarm.DapJavaOpts
  opts = {
    host = "127.0.0.1", -- where the Grails JVM listens
    port = 5005, -- default JDWP port used by Gradle / Grails wrappers
    project_name = "xfarm-server",
  },

  ---@param opts xfarm.DapJavaOpts
  config = function(_, opts)
    local dap = require("dap")

    -- Adapter: one per session – we expose a function so each attach call can
    -- override host/port if it needs to.
    dap.adapters.java = function(callback, cfg)
      callback({
        type = "server",
        host = cfg.host or opts.host,
        port = cfg.port or opts.port,
      })
    end

    -- Handy reusable attach configuration for both Java *and* Groovy files.
    local attach = {
      type = "java",
      request = "attach",
      name = "Attach to Grails (" .. opts.port .. ")",
      host = opts.host,
      port = opts.port,
      projectName = opts.project_name,
    }

    for _, ft in ipairs({ "java", "groovy" }) do
      dap.configurations[ft] = { attach }
    end
  end,
}
