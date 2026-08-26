-- Groovy / Grails support (xfarm-server and friends).
-- LazyVim ships no lang.groovy extra, so this is the equivalent, wired for a
-- Gradle project: groovyls with a real classpath, CodeNarc linting through
-- npm-groovy-lint, treesitter, and Grails view-template filetypes.

local groovy = nil
local function util()
  groovy = groovy or require("util.groovy")
  return groovy
end

local mason_jar = vim.fn.stdpath("data")
  .. "/mason/packages/groovy-language-server/build/libs/groovy-language-server-all.jar"

-- CodeNarc rules for on-save linting live outside the repo so the shared
-- project config stays untouched. `--config` wants the containing directory.
local lint_config_dir = vim.fn.stdpath("config") .. "/groovy"

-- Formatting is restricted to these fixers. npm-groovy-lint's --format mode
-- also runs formatting.Indentation, whose fixer re-indents closing braces to
-- arbitrary columns on real files in this repo (verified: it moved `}` out to
-- column 31 in AnalyticsUtilityService). Everything below is whitespace or
-- punctuation only, idempotent, and matches .claude/rules/code-style.md.
local fix_rules = table.concat({
  "UnnecessarySemicolon",
  "SpaceAfterIf",
  "SpaceAfterFor",
  "SpaceAfterWhile",
  "SpaceAfterSwitch",
  "SpaceAfterCatch",
  "SpaceAfterComma",
  "SpaceAfterSemicolon",
  "SpaceAfterMethodCallName",
  "SpaceAroundOperator",
  "TrailingWhitespace",
  "FileEndsWithoutNewline",
  "MissingBlankLineAfterImports",
  "MissingBlankLineAfterPackage",
  "NoTabCharacter",
}, ",")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "groovy" } },
    init = function()
      -- Neovim maps .gradle to filetype groovy, which makes gradle_ls and
      -- groovyls fight over every Groovy buffer: both advertise "groovy", so
      -- each file gets two servers and two sets of diagnostics. Giving build
      -- scripts and .gson views their own filetypes keeps one server per file.
      -- Detaching after the fact is not enough -- a server keeps publishing
      -- diagnostics for a URI it has open.
      vim.filetype.add({ extension = { gradle = "gradle", gson = "gson" } })
      vim.treesitter.language.register("groovy", "gradle")
      vim.treesitter.language.register("groovy", "gson")
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "gradle", "gson" },
        group = vim.api.nvim_create_augroup("groovy_dialects", { clear = true }),
        callback = function(ev)
          vim.bo[ev.buf].commentstring = "// %s"
          pcall(vim.treesitter.start, ev.buf, "groovy")
        end,
      })
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "groovy-language-server" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local jdk = util().jdk_home(util().root(vim.uv.cwd()) or "")
      local java = jdk and (jdk .. "/bin/java") or "java"

      opts.servers = opts.servers or {}
      -- Project sources. The workspace is ~2400 Groovy files and groovyls
      -- compiles all of it, so it needs a real heap. settings.groovy.classpath
      -- is injected on attach, once Gradle has told us what it is.
      opts.servers.groovyls = {
        cmd = { java, "-Xmx3g", "-jar", mason_jar },
        filetypes = { "groovy" },
      }
      -- Build scripts only.
      opts.servers.gradle_ls = { filetypes = { "gradle" } }
    end,
    init = function()
      local g = util()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("groovy_lsp", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "groovyls" then
            return
          end
          local root = client.config.root_dir or g.root(vim.api.nvim_buf_get_name(args.buf))
          if root then
            g.ensure(root)
          end
        end,
      })

      vim.api.nvim_create_user_command("GroovyClasspath", function()
        local root = g.root(vim.api.nvim_buf_get_name(0))
        if not root then
          return vim.notify("groovy: no Gradle project found", vim.log.levels.WARN)
        end
        local classpath = g.load(root)
        vim.notify(
          ("groovy: %s\njdk: %s\nclasspath: %s%s"):format(
            root,
            g.jdk_home(root) or "not found",
            classpath and (#classpath .. " entries") or "not cached",
            g.is_stale(root) and " (stale)" or ""
          ),
          vim.log.levels.INFO
        )
      end, { desc = "Groovy: classpath status" })

      vim.api.nvim_create_user_command("GroovyClasspathRefresh", function()
        local root = g.root(vim.api.nvim_buf_get_name(0))
        if root then
          g.generate(root)
        end
      end, { desc = "Groovy: re-resolve the Gradle classpath" })

    end,
  },

  -- Gradle 7.6.6 cannot run on JDK 21+, and the system default here is newer.
  -- Point jdtls's Gradle import and its compiler at the JDK the project pins.
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    opts = function(_, opts)
      local jdk = util().jdk_home(util().root(vim.uv.cwd()) or "")
      if not jdk then
        return
      end
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            runtimes = { { name = "JavaSE-17", path = jdk, default = true } },
          },
          import = {
            gradle = {
              enabled = true,
              wrapper = { enabled = true },
              java = { home = jdk },
            },
          },
        },
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      -- .gradle and .gson are Groovy too: they get the same whitespace fixers
      -- (verified safe on build.gradle and on a real .gson view), but not the
      -- linter, which reports the Gradle DSL and view models as unused vars.
      formatters_by_ft = {
        groovy = { "npm-groovy-lint" },
        gradle = { "npm-groovy-lint" },
        gson = { "npm-groovy-lint" },
      },
      formatters = {
        ["npm-groovy-lint"] = {
          -- function form: a plain list would be merged index-wise with the
          -- built-in { "--fix", "$FILENAME" } args
          args = function()
            return {
              "--config",
              lint_config_dir,
              "--fix",
              "--fixrules",
              fix_rules,
              "--failon",
              "none",
              "$FILENAME",
            }
          end,
        },
      },
    },
    init = function()
      -- Format on demand (<leader>cf), never on save: this is a legacy
      -- codebase and reformatting whole files on every write buries the real
      -- change in unrelated diff noise. Flip the buffer flag to opt in.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "groovy", "gradle", "gson" },
        group = vim.api.nvim_create_augroup("groovy_format", { clear = true }),
        callback = function(ev)
          vim.b[ev.buf].autoformat = false
        end,
      })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = { groovy = { "npm-groovy-lint" } },
      linters = {
        ["npm-groovy-lint"] = {
          args = {
            "--config",
            lint_config_dir,
            -- keep the exit code at 0 so nvim-lint does not flag a failed run
            "--failon",
            "none",
            "-o",
            "txt",
          },
        },
      },
    },
  },
}
