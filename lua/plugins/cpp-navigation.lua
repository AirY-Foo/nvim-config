local docker = require("config.machine").docker
local function normalize(path)
  return vim.fs.normalize(path):gsub("\\", "/"):gsub("/+$", "")
end
local host_root = normalize(docker.host_root)
local function equal(a, b)
  if vim.fn.has("win32") == 1 then return a:lower() == b:lower() end
  return a == b
end
local function remote_project(path)
  if not docker.enabled or host_root == "" then return end
  path = normalize(path)
  if not equal(path:sub(1, #host_root + 1), host_root .. "/") then return end
  local project = path:sub(#host_root + 2):match("^([^/]+)")
  if not project then return end
  for _, pattern in ipairs(docker.project_patterns) do
    if project:match(pattern) then
      return normalize(docker.container_root) .. "/" .. project, host_root .. "/" .. project
    end
  end
end
local function switch_header()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })[1]
  if not client then return vim.notify("clangd is not attached", vim.log.levels.WARN) end
  client:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(), function(err, uri)
    if err then return vim.notify(err.message, vim.log.levels.ERROR) end
    if not uri or uri == "" then return vim.notify("No matching source/header found") end
    vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri)))
  end, 0)
end
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local cfg = opts.servers.clangd or {}
      cfg.capabilities = vim.tbl_deep_extend("force", cfg.capabilities or {}, {
        offsetEncoding = { "utf-16" }, general = { positionEncodings = { "utf-16" } },
      })
      cfg.root_dir = function(buf, on_dir)
        local _, root = remote_project(vim.api.nvim_buf_get_name(buf))
        on_dir(root or vim.fs.root(buf, { ".clangd", "compile_commands.json", "CMakeLists.txt", ".git" })
          or vim.fs.dirname(vim.api.nvim_buf_get_name(buf)))
      end
      cfg.cmd = function(dispatchers, config)
        local project = remote_project(config.root_dir or "")
        local command = { "clangd", "--background-index", "--completion-style=detailed", "--header-insertion=never", "--log=error" }
        if project then
          local client_root = vim.fn.has("win32") == 1 and ("/" .. host_root) or host_root
          command = { "docker", "exec", "-i", docker.container, docker.clangd,
            "--background-index", "-j=" .. docker.jobs, "--completion-style=detailed",
            "--header-insertion=never", "--log=error",
            "--compile-commands-dir=" .. project .. "/" .. docker.build_dir,
            "--path-mappings=" .. client_root .. "=" .. normalize(docker.container_root) }
        end
        return vim.lsp.rpc.start(command, dispatchers, { cwd = config.cmd_cwd, env = config.cmd_env })
      end
      local attached = cfg.on_attach
      cfg.on_attach = function(client, buf)
        if attached then attached(client, buf) end
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) then return end
          local function map(key, fn, desc)
            vim.keymap.set("n", key, fn, { buffer = buf, desc = desc, silent = true })
          end
          map("gd", vim.lsp.buf.definition, "C++: definition")
          map("gD", vim.lsp.buf.declaration, "C++: declaration")
          map("gr", function() Snacks.picker.lsp_references() end, "C++: references")
          map("<leader>ch", switch_header, "C++: switch source/header")
        end)
      end
      opts.servers.clangd = cfg
    end,
  },
}
