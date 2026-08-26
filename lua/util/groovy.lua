-- Gradle-backed classpath resolution for the Groovy language server.
--
-- groovyls only resolves types it can find on its classpath, and it has no idea
-- how to read a Gradle build. We ask Gradle for the resolved compile classpath
-- once, cache it, and push it to the server via workspace/didChangeConfiguration
-- (settings.groovy.classpath -- see GroovyServices.updateClasspath).

local M = {}

local START = "LSP_CLASSPATH_START"
local STOP = "LSP_CLASSPATH_END"

M.init_script = vim.fn.stdpath("config") .. "/gradle/lsp-classpath.init.gradle"

---Root of the nearest Gradle project above `path`.
---@param path string?
---@return string?
function M.root(path)
  path = (path == nil or path == "") and (vim.uv.cwd() or ".") or path
  local marker = vim.fs.find({ "settings.gradle", "settings.gradle.kts", "build.gradle" }, {
    path = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path),
    upward = true,
  })[1]
  return marker and vim.fs.dirname(marker) or nil
end

---Java home matching the project's toolchain.
---Honours the major version pinned in .sdkmanrc, since Gradle 7.x cannot run on
---a JDK newer than 19 and the system default here is 21+.
---@param root string
---@return string?
function M.jdk_home(root)
  local major = "17"
  local sdkmanrc = root .. "/.sdkmanrc"
  if vim.fn.filereadable(sdkmanrc) == 1 then
    for _, line in ipairs(vim.fn.readfile(sdkmanrc)) do
      local version = line:match("^%s*java%s*=%s*(%S+)")
      if version then
        major = version:match("^(%d+)") or major
        -- an sdkman-managed JDK is the most faithful match
        local candidate = vim.fn.expand("~/.sdkman/candidates/java/" .. version)
        if vim.fn.executable(candidate .. "/bin/java") == 1 then
          return candidate
        end
      end
    end
  end
  for _, pattern in ipairs({
    "/usr/lib/jvm/java-" .. major .. "-openjdk",
    "/usr/lib/jvm/java-" .. major .. "-openjdk*",
    "/usr/lib/jvm/jdk-" .. major .. "*",
    "/usr/lib/jvm/*-" .. major .. "-*",
    vim.fn.expand("~/.sdkman/candidates/java/" .. major .. "*"),
  }) do
    for _, dir in ipairs(vim.fn.glob(pattern, true, true)) do
      if vim.fn.executable(dir .. "/bin/java") == 1 then
        return dir
      end
    end
  end
  return nil
end

local function cache_path(root)
  local dir = vim.fn.stdpath("cache") .. "/groovy-classpath"
  vim.fn.mkdir(dir, "p")
  return dir .. "/" .. vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 12) .. ".json"
end

---@return string[]|nil classpath, number|nil mtime
function M.load(root)
  local path = cache_path(root)
  if vim.fn.filereadable(path) == 0 then
    return nil, nil
  end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(decoded) ~= "table" or type(decoded.classpath) ~= "table" then
    return nil, nil
  end
  return decoded.classpath, vim.fn.getftime(path)
end

---True when build.gradle has been touched since the cache was written.
function M.is_stale(root)
  local _, mtime = M.load(root)
  if not mtime then
    return false
  end
  for _, name in ipairs({ "build.gradle", "settings.gradle", "gradle.properties" }) do
    local ftime = vim.fn.getftime(root .. "/" .. name)
    if ftime > 0 and ftime > mtime then
      return true
    end
  end
  return false
end

---Push a classpath to every running groovyls client.
---@param classpath string[]
function M.apply(classpath)
  for _, client in ipairs(vim.lsp.get_clients({ name = "groovyls" })) do
    client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
      groovy = { classpath = classpath },
    })
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  end
end

local running = {}

---Ask Gradle for the compile classpath, cache it, and push it to the server.
---@param root string
---@param opts? { silent?: boolean }
function M.generate(root, opts)
  opts = opts or {}
  if running[root] then
    return
  end

  local gradlew = root .. "/gradlew"
  local cmd = vim.fn.executable(gradlew) == 1 and { gradlew } or { "gradle" }
  if cmd[1] == "gradle" and vim.fn.executable("gradle") == 0 then
    vim.notify("groovy: no gradlew or gradle on PATH", vim.log.levels.ERROR)
    return
  end
  vim.list_extend(cmd, { "--init-script", M.init_script, "-q", "lspClasspath" })

  local env = {}
  local jdk = M.jdk_home(root)
  if jdk then
    env.JAVA_HOME = jdk
  end

  running[root] = true
  if not opts.silent then
    vim.notify("groovy: resolving classpath via Gradle...", vim.log.levels.INFO)
  end

  vim.system(cmd, { cwd = root, env = env, text = true }, function(res)
    running[root] = nil
    -- This runs in a fast event context: only libuv and pure Lua are allowed
    -- here, so stat with vim.uv and defer everything else to vim.schedule.
    local classpath = {}
    local collecting = false
    for _, line in ipairs(vim.split(res.stdout or "", "\n", { trimempty = true })) do
      line = vim.trim(line)
      if line == START then
        collecting = true
      elseif line == STOP then
        collecting = false
      elseif collecting and vim.uv.fs_stat(line) then
        table.insert(classpath, line)
      end
    end

    vim.schedule(function()
      if #classpath == 0 then
        vim.notify(
          ("groovy: Gradle returned no classpath (exit %d)\n%s"):format(res.code, res.stderr or ""),
          vim.log.levels.ERROR
        )
        return
      end
      vim.fn.writefile(
        { vim.json.encode({ root = root, jdk = jdk, classpath = classpath }) },
        cache_path(root)
      )
      M.apply(classpath)
      vim.notify(("groovy: classpath resolved (%d entries)"):format(#classpath), vim.log.levels.INFO)
    end)
  end)
end

---Called on groovyls attach: use the cache if present, otherwise build it.
---@param root string
function M.ensure(root)
  local classpath = M.load(root)
  if classpath then
    M.apply(classpath)
    if M.is_stale(root) then
      vim.notify("groovy: build.gradle changed since the classpath was cached -- :GroovyClasspath refresh", vim.log.levels.WARN)
    end
    return
  end
  M.generate(root)
end

return M
