-- Shared defaults. Keep device-specific overrides in ignored config/local.lua.
local defaults = {
  shell = vim.fn.executable("nu") == 1 and "nu" or vim.o.shell,
  codex_args = {},
  docker = {
    enabled = false,
    container = "miivii_dev",
    host_root = "",
    container_root = "/home/nvidia/workspace/src",
    clangd = "clangd-12",
    build_dir = "build",
    jobs = 2,
    display = "host.docker.internal:0",
    project_patterns = { "^igv_", "^get_all_path_tools$" },
  },
}
local path = vim.fn.stdpath("config") .. "/lua/config/local.lua"
if vim.uv.fs_stat(path) then
  local overrides = require("config.local")
  assert(type(overrides) == "table", "config/local.lua must return a table")
  return vim.tbl_deep_extend("force", defaults, overrides)
end
return defaults
