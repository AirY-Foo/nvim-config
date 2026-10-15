local root = vim.fn.getcwd():gsub("\\", "/")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local count = 0
for _, pattern in ipairs({ "/lua/**/*.lua", "/tests/*.lua", "/init.lua" }) do
  for _, path in ipairs(vim.fn.glob(root .. pattern, false, true)) do
    assert(loadfile(path))
    count = count + 1
  end
end
local machine = require("config.machine")
assert(not machine.docker.enabled, "Smoke tests must use defaults without a local.lua override")
assert(type(machine.shell) == "string" and #machine.shell > 0)
local M = {}
local items, choose, result
M.agent = function(prompt) result = prompt end
M.visual_selection = require("config.selection")(M)
vim.ui.select = function(options, _, cb) items, choose = options, cb end
vim.api.nvim_buf_set_name(0, root .. "/tests/selection.cpp")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "int a;", "int b;", "int c;" })
vim.cmd.normal({ args = { "ggVj" }, bang = true })
M.visual_selection()
assert(#items == 6 and result == nil)
local original_buf = vim.api.nvim_get_current_buf()
vim.cmd.enew()
for i = 1, 5 do
  choose(items[i])
  assert(result:find(items[i].instruction, 1, true))
  assert(result:find("int a;\nint b;", 1, true))
end
result = nil
choose(nil)
assert(result == nil)
vim.ui.input = function(_, cb) cb("explain locking") end
choose(items[6])
assert(result:find("explain locking", 1, true))
vim.api.nvim_set_current_buf(original_buf)
vim.cmd.normal({ args = { "GVk" }, bang = true })
M.visual_selection()
choose(items[1])
assert(result:find("int b;\nint c;", 1, true))
local captured
vim.lsp.rpc.start = function(cmd) captured = cmd; return {} end
local opts = { servers = { clangd = {} } }
local spec = dofile(root .. "/lua/plugins/cpp-navigation.lua")
spec[1].opts(nil, opts)
opts.servers.clangd.cmd({}, { root_dir = root })
assert(captured[1] == "clangd", "Default config must not depend on Docker")
machine.docker.enabled = true
machine.docker.host_root = root
machine.docker.container_root = "/test/src"
spec = dofile(root .. "/lua/plugins/cpp-navigation.lua")
opts = { servers = { clangd = {} } }
spec[1].opts(nil, opts)
opts.servers.clangd.cmd({}, { root_dir = root .. "/igv_demo" })
assert(captured[1] == "docker")
assert(vim.tbl_contains(captured, "--compile-commands-dir=/test/src/igv_demo/build"))
opts.servers.clangd.cmd({}, { root_dir = root .. "-other/igv_demo" })
assert(captured[1] == "clangd", "Mapping must respect directory boundaries")
print("PASS: " .. count .. " Lua files; selection actions; native/Docker C++ transport; path boundaries")
vim.cmd("qa!")
