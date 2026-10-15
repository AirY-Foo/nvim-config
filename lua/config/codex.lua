local M = {}
local machine = require("config.machine")

local root_markers = {
  ".git", ".codex", "package.json", "pyproject.toml", "Cargo.toml", "go.mod",
  "compose.yaml", "compose.yml", "docker-compose.yml", "Dockerfile", "CMakeLists.txt",
}

local function project_root()
  local buffer_path = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(buffer_path ~= "" and buffer_path or 0, root_markers) or vim.fn.getcwd()
end

local function has_codex()
  if vim.fn.executable("codex") == 1 then return true end
  vim.notify("Cannot find codex on PATH. Restart Neovim after installing or updating Codex CLI.", vim.log.levels.ERROR)
  return false
end

local function terminal(command, title, cwd)
  require("lazy").load({ plugins = { "snacks.nvim" } })
  local snacks = require("snacks")
  local opts = {
    cwd = cwd or project_root(),
    win = { position = "float", title = title },
  }

  -- `Snacks.terminal()` toggles an existing terminal with the same command.
  -- `focus` always brings that terminal back to the foreground and only starts
  -- a process when needed.
  snacks.terminal.focus(command, opts)
end

local function codecompanion()
  require("lazy").load({ plugins = { "codecompanion.nvim" } })
  return require("codecompanion")
end

local function codex_cli(prompt)
  if not has_codex() then return end
  local companion = codecompanion()
  if prompt and prompt ~= "" then
    companion.cli(prompt, { agent = "codex", submit = true })
  else
    companion.toggle_cli({ agent = "codex" })
  end
end

function M.yazi()
  if vim.fn.executable("yazi") == 0 then
    vim.notify("Cannot find yazi on PATH. Restart Neovim after installing or updating Yazi.", vim.log.levels.ERROR)
    return
  end

  local file = vim.api.nvim_buf_get_name(0)
  local cwd = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or project_root()
  terminal({ "yazi" }, "Yazi", cwd)
end

local function current_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Open a file first", vim.log.levels.WARN)
    return nil
  end
  return file
end

function M.agent(prompt)
  codex_cli(prompt)
end

function M.ask()
  vim.ui.input({ prompt = "Codex prompt: " }, function(prompt)
    if prompt and prompt ~= "" then M.agent(prompt) end
  end)
end

function M.fix_current_file()
  local file = current_file()
  if not file then return end
  M.agent(string.format(
    "Review %s. Identify the smallest safe fix, explain it briefly, then apply it only after checking the relevant context.", file
  ))
end

function M.selection(line1, line2)
  local file = current_file()
  if not file then return end
  local text = table.concat(vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false), "\n")
  if text == "" then
    vim.notify("Select some text first", vim.log.levels.WARN)
    return
  end
  M.agent(string.format(
    "In %s, review lines %d-%d below. Explain issues and suggest the smallest improvement. Do not edit unrelated code.\n\n%s",
    file, line1, line2, text
  ))
end

M.visual_selection = require("config.selection")(M)

-- Kept for configurations where :CodexSelection passes the user-command
-- callback directly instead of wrapping it in a function.
function M.ask_selection(command)
  local first = command and command.line1 or vim.fn.line("'<")
  local last = command and command.line2 or vim.fn.line("'>")
  if first > 0 and last >= first then M.selection(first, last) end
end

function M.review()
  codex_cli("Review the current Git changes. Identify correctness, safety, and maintainability issues, then suggest or apply only well-justified fixes.")
end

function M.resume()
  if not has_codex() then return end
  codecompanion().cli({ agent = "codex_resume" })
end

function M.doctor()
  if not has_codex() then return end
  codecompanion().cli({ agent = "codex_doctor" })
end

function M.diff()
  if vim.fn.executable("git") == 0 then
    vim.notify("Cannot find git on PATH", vim.log.levels.ERROR)
    return
  end
  terminal({ "git", "diff", "--stat" }, "Git: current diff summary")
end

function M.compose(command, title) terminal(command, title) end

local function posix_quote(value)
  -- The remote command is interpreted by the login shell on the Linux host.
  -- Quote it here rather than relying on the Windows shell's quoting rules.
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function deploy_deb(host, package, deploy_password)
  if vim.fn.executable("scp") == 0 or vim.fn.executable("ssh") == 0 then
    vim.notify("Cannot find both scp and ssh on PATH.", vim.log.levels.ERROR)
    return
  end
  if host == "" or host:find("%s") or host:sub(1, 1) == "-" then
    vim.notify("Remote host must look like user@host (and cannot start with '-').", vim.log.levels.ERROR)
    return
  end

  package = vim.fn.fnamemodify(package, ":p")
  if package:sub(-4):lower() ~= ".deb" or vim.fn.filereadable(package) == 0 then
    vim.notify("Choose an existing .deb package.", vim.log.levels.ERROR)
    return
  end

  if not deploy_password or deploy_password == "" then
    vim.notify("A password is required to deploy the package.", vim.log.levels.ERROR)
    return
  end

  local package_name = vim.fn.fnamemodify(package, ":t")
  local askpass = vim.fn.stdpath("config") .. "\\bin\\debdeploy-askpass.exe"
  if vim.fn.executable(askpass) == 0 then
    vim.notify("Cannot find DebDeploy askpass helper: " .. askpass, vim.log.levels.ERROR)
    return
  end
  local ssh_env = {
    SSH_ASKPASS = askpass,
    SSH_ASKPASS_REQUIRE = "force",
    DISPLAY = "nvim-debdeploy",
    NVIM_DEBDEPLOY_PASSWORD = deploy_password,
  }
  local ssh_options = {
    "-o", "StrictHostKeyChecking=accept-new",
    "-o", "ConnectTimeout=10",
    "-o", "ServerAliveInterval=5",
    "-o", "ServerAliveCountMax=3",
  }
  -- Use a path relative to the SSH user's home directory for scp, which also
  -- works with newer scp clients that transfer over SFTP.
  local remote_target = host .. ":fq/" .. package_name
  local remote_package = "\"$HOME/fq/\"" .. posix_quote(package_name)

  -- Keep one notification alive for the whole deployment. Apart from making
  -- the current stage explicit, elapsed time shows that SSH/SCP is still
  -- running instead of silently hanging.
  require("lazy").load({ plugins = { "snacks.nvim" } })
  local progress_id = "deb-deploy-" .. tostring(vim.uv.hrtime())
  local progress_timer

  local function notify_progress(message, level, finished)
    vim.notify(message, level or vim.log.levels.INFO, {
      id = progress_id,
      title = "DebDeploy",
      timeout = finished and 6000 or false,
    })
  end

  local function stop_progress_timer()
    if progress_timer and not progress_timer:is_closing() then
      progress_timer:stop()
      progress_timer:close()
    end
    progress_timer = nil
  end

  local function start_stage(step, message)
    stop_progress_timer()
    local started = vim.uv.hrtime()
    notify_progress(string.format("[%d/3] %s", step, message))
    local timer = vim.uv.new_timer()
    progress_timer = timer
    timer:start(1000, 1000, vim.schedule_wrap(function()
      if progress_timer == timer and not timer:is_closing() then
        local elapsed = math.floor((vim.uv.hrtime() - started) / 1e9)
        notify_progress(string.format("[%d/3] %s (%ds)", step, message, elapsed))
      end
    end))
  end

  local function finish(message, level)
    stop_progress_timer()
    notify_progress(message, level, true)
  end

  local function upload()
    start_stage(2, "Uploading " .. package_name .. " to " .. host .. ":~/fq/")
    local command = { "scp" }
    vim.list_extend(command, ssh_options)
    vim.list_extend(command, { "--", package, remote_target })
    vim.system(command, { text = true, env = ssh_env }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          finish("Upload failed:\n" .. (result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
          return
        end

        -- Remove the staged package only after a successful installation so it
        -- remains available for diagnosis if dpkg reports an error.
        local install = "sudo -S -p '' dpkg -i -- " .. remote_package
          .. " && rm -f -- " .. remote_package
        start_stage(3, "Installing " .. package_name .. " on " .. host)
        local command = { "ssh", "-tt" }
        vim.list_extend(command, ssh_options)
        vim.list_extend(command, { "--", host, install })
        vim.system(command, {
          text = true,
          env = ssh_env,
          stdin = deploy_password .. "\n",
        }, function(install_result)
          vim.schedule(function()
            if install_result.code == 0 then
              finish("Deployment complete: " .. package_name .. " installed on " .. host, vim.log.levels.INFO)
              vim.cmd.checktime()
            else
              local output = install_result.stderr ~= "" and install_result.stderr or install_result.stdout
              finish("Installation failed:\n" .. output, vim.log.levels.ERROR)
            end
          end)
        end)
      end)
    end)
  end

  -- Create ~/fq first: an scp destination does not create parent directories.
  start_stage(1, "Preparing " .. host .. ":~/fq/")
  local command = { "ssh" }
  vim.list_extend(command, ssh_options)
  vim.list_extend(command, { "--", host, "mkdir -p -- \"$HOME/fq\"" })
  vim.system(command, { text = true, env = ssh_env }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        finish("Could not create ~/fq on " .. host .. ":\n"
          .. (result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
        return
      end
      upload()
    end)
  end)
end

function M.deploy_deb(args)
  local host, package = args[1] or "", args[2] or ""
  if #args > 2 then
    vim.notify("Usage: :DebDeploy [user@host] [path/to/package.deb]", vim.log.levels.ERROR)
    return
  end

  local function ask_password()
    local password = vim.fn.inputsecret("SSH/sudo password: ")
    if password == "" then
      vim.notify("Deployment cancelled: no password entered.", vim.log.levels.WARN)
      return
    end
    deploy_deb(host, package, password)
  end

  local function ask_package()
    if package ~= "" then
      ask_password()
      return
    end
    local current = vim.api.nvim_buf_get_name(0)
    local default = current:sub(-4):lower() == ".deb" and current or ""
    vim.ui.input({ prompt = "Local .deb path: ", default = default, completion = "file" }, function(value)
      if value and value ~= "" then
        package = value
        ask_password()
      end
    end)
  end

  if host == "" then
    vim.ui.input({ prompt = "Remote SSH host (user@host): " }, function(value)
      if value and value ~= "" then
        host = value
        ask_package()
      end
    end)
  else
    ask_package()
  end
end

function M.nushell()
  local nu = vim.fn.exepath("nu")
  if nu == "" then
    vim.notify("Cannot find nu.exe. Restart Windows Terminal, then retry.", vim.log.levels.ERROR)
    return
  end
  terminal({ nu }, "Nushell")
end

local miivii_container = machine.docker.container

local function normalize_windows_path(path)
  local normalized = path:gsub("\\", "/"):gsub("/+$", "")
  return vim.fn.has("win32") == 1 and normalized:lower() or normalized
end

local function container_project_root(host_root)
  local mounts = vim.fn.system({ "docker", "inspect", "-f", "{{json .Mounts}}", miivii_container })
  if vim.v.shell_error ~= 0 then return nil end

  local ok, decoded = pcall(vim.json.decode, mounts)
  if not ok then return nil end

  -- Select the deepest bind mount containing the project. This keeps the
  -- mapping correct if the container later gains a more specific mount.
  local best_source, best_destination
  local normalized_root = normalize_windows_path(host_root)
  for _, mount in ipairs(decoded) do
    if mount.Type == "bind" and mount.Source and mount.Destination then
      local source = normalize_windows_path(mount.Source)
      if normalized_root == source or normalized_root:sub(1, #source + 1) == source .. "/" then
        if not best_source or #source > #best_source then
          best_source, best_destination = source, mount.Destination
        end
      end
    end
  end

  if not best_source then return nil end
  local suffix = host_root:gsub("\\", "/"):sub(#best_source + 1)
  return best_destination:gsub("/$", "") .. suffix
end

local function miivii_project_root()
  if vim.fn.executable("docker") == 0 then
    vim.notify("Cannot find docker.exe. Start Docker Desktop, then retry.", vim.log.levels.ERROR)
    return nil
  end
  local state = vim.fn.system({ "docker", "inspect", "-f", "{{.State.Running}}", miivii_container })
  if vim.v.shell_error ~= 0 then
    vim.notify("Cannot find container " .. miivii_container .. ". Start Docker Desktop first.", vim.log.levels.ERROR)
    return nil
  end
  if vim.trim(state) ~= "true" then
    vim.notify("Start miivii_dev first with :MiiviiShell, then retry.", vim.log.levels.WARN)
    return nil
  end
  local root = container_project_root(project_root())
  if not root then
    vim.notify("This project is not mapped into miivii_dev.", vim.log.levels.ERROR)
    return nil
  end
  return root
end

local function miivii_ros_command(command)
  -- The host is Windows, but CMake and catkin run inside the Linux container.
  -- Loading ROS here supplies catkinConfig.cmake through CMAKE_PREFIX_PATH.
  local ros_setup = 'ros_setup="$(find /opt/ros -mindepth 2 -maxdepth 2 -name setup.bash -print -quit)"; '
  return ros_setup
    .. 'if [ -z "$ros_setup" ]; then echo "ROS setup.bash was not found in /opt/ros"; exit 1; fi; '
    .. 'source "$ros_setup"; ' .. command
end

function M.miivii_cmake_configure()
  local root = miivii_project_root()
  if not root then return end
  local quoted_root = vim.fn.shellescape(root)
  local command = string.format(
    "cmake -S %s -B %s/build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
    quoted_root, quoted_root
  )
  terminal({ "docker", "exec", "-it", miivii_container, "/bin/bash", "-lc", miivii_ros_command(command) },
    "miivii: CMake configure (catkin)")
end

function M.miivii_cmake_build()
  local root = miivii_project_root()
  if not root then return end
  local command = string.format("cmake --build %s/build", vim.fn.shellescape(root))
  terminal({ "docker", "exec", "-it", miivii_container, "/bin/bash", "-lc", miivii_ros_command(command) },
    "miivii: CMake build")
end

local function miivii_tmux_session()
  -- Keep sessions separate when the same container is used for multiple
  -- projects, while leaving a stable name to reattach after restarting Nvim.
  local project = vim.fn.fnamemodify(project_root(), ":t"):gsub("[^%w_-]", "_")
  return "nvim-" .. (project ~= "" and project or "shell")
end

local function open_miivii_tmux(container_root)
  local session = miivii_tmux_session()
  local command = { "docker", "exec", "-it" }
  if container_root then
    table.insert(command, "-w")
    table.insert(command, container_root)
  end
  local tmux_env = "tmux new-session -Ad -s " .. vim.fn.shellescape(session)
    .. "; tmux set-environment -t " .. vim.fn.shellescape(session) .. " DISPLAY " .. posix_quote(machine.docker.display)
    .. "; tmux set-environment -t " .. vim.fn.shellescape(session) .. " QT_X11_NO_MITSHM 1"
    .. "; tmux set-environment -t " .. vim.fn.shellescape(session) .. " LIBGL_ALWAYS_SOFTWARE 1"
    .. "; exec tmux attach-session -t " .. vim.fn.shellescape(session)
  vim.list_extend(command, {
    -- Use an interactive Bash so it loads /root/.bashrc, where the X11
    -- variables for RViz are configured.
    miivii_container, "/bin/bash", "-ic",
    tmux_env,
  })
  terminal(command, "miivii: tmux (" .. session .. ")")
end

function M.miivii_shell()
  if vim.fn.executable("docker") == 0 then
    vim.notify("Cannot find docker.exe. Start Docker Desktop, then retry.", vim.log.levels.ERROR)
    return
  end
  local state = vim.fn.system({ "docker", "inspect", "-f", "{{.State.Running}}", miivii_container })
  if vim.v.shell_error ~= 0 then
    vim.notify("Cannot find container " .. miivii_container .. ". Start Docker Desktop first.", vim.log.levels.ERROR)
    return
  end
  if vim.trim(state) ~= "true" then
    vim.fn.system({ "docker", "start", miivii_container })
    if vim.v.shell_error ~= 0 then
      vim.notify("Could not start " .. miivii_container .. ". Start Docker Desktop, then retry.", vim.log.levels.ERROR)
      return
    end
  end

  local container_root = container_project_root(project_root())
  if not container_root then
    vim.notify("Could not map this project into miivii_dev; using the container default directory.", vim.log.levels.WARN)
  end
  open_miivii_tmux(container_root)
end

local function docker_containers()
  local result = vim.system({ "docker", "container", "ls", "-a", "--format", "{{.Names}}\t{{.State}}\t{{.Image}}" },
    { text = true }):wait()
  if result.code ~= 0 then
    vim.notify("Could not list Docker containers. Start Docker Desktop, then retry.\n"
      .. (result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
    return nil
  end

  local containers = {}
  for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
    local name, state, image = line:match("^([^\t]+)\t([^\t]+)\t(.*)$")
    if name then table.insert(containers, { name = name, state = state, image = image }) end
  end
  return containers
end

local function start_container_if_needed(name)
  local result = vim.system({ "docker", "inspect", "-f", "{{.State.Running}}", name }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify("Cannot find container " .. name .. ".", vim.log.levels.ERROR)
    return false
  end
  if vim.trim(result.stdout) == "true" then return true end

  result = vim.system({ "docker", "start", name }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify("Could not start " .. name .. ":\n"
      .. (result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function open_container_shell(name)
  if name == miivii_container then
    -- Preserve the project-aware tmux session used by the existing ROS/CMake
    -- workflow, while presenting it in the same chooser as other containers.
    M.miivii_shell()
    return
  end
  if not start_container_if_needed(name) then return end

  -- Prefer Bash when available (ROS setup files use it), but retain support
  -- for minimal images that only ship with /bin/sh.
  local probe = vim.system({ "docker", "exec", name, "/bin/sh", "-c", "command -v bash" }, { text = true }):wait()
  local shell = probe.code == 0 and vim.trim(probe.stdout) ~= "" and "bash" or "sh"
  terminal({ "docker", "exec", "-it", name, shell }, "Docker: " .. name)
end

function M.container_shell(name)
  if vim.fn.executable("docker") == 0 then
    vim.notify("Cannot find docker.exe. Start Docker Desktop, then retry.", vim.log.levels.ERROR)
    return
  end
  if name and name ~= "" then
    open_container_shell(name)
    return
  end

  local containers = docker_containers()
  if not containers then return end
  if #containers == 0 then
    vim.notify("No Docker containers exist yet.", vim.log.levels.WARN)
    return
  end

  vim.ui.select(containers, {
    prompt = "Enter Docker container:",
    format_item = function(item)
      local label = item.name == miivii_container and " (project tmux)" or ""
      return string.format("%s%s — %s — %s", item.name, label, item.state, item.image)
    end,
  }, function(item)
    if item then open_container_shell(item.name) end
  end)
end

function M.miivii_logs()
  terminal({ "docker", "logs", "-f", "--tail=150", miivii_container }, "miivii: logs")
end

return M
