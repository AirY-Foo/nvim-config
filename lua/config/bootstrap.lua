local M = {}
local function checked(action)
  local ok, err = pcall(action)
  if not ok then
    vim.api.nvim_err_writeln(tostring(err))
    vim.cmd("cquit 1")
  end
end
function M.plugins()
  checked(function()
    local manager = require("lazy.manage")
    manager.install({ wait = true, show = false, lockfile = true })
    manager.restore({ wait = true, show = false })
    local failed = {}
    for name, plugin in pairs(require("lazy.core.config").plugins) do
      local bad = plugin.url and not plugin._.installed
      for _, task in ipairs(plugin._.tasks or {}) do bad = bad or task:has_errors() end
      if bad then failed[#failed + 1] = name end
    end
    if #failed > 0 then error("Plugin install failed: " .. table.concat(failed, ", ")) end
  end)
end
function M.run()
  require("lazy").load({ plugins = { "mason.nvim", "nvim-lspconfig" } })
  local registry = require("mason-registry")
  local ready, success = false, false
  registry.refresh(function(ok) success = ok; ready = true end)
  if not vim.wait(120000, function() return ready end, 100) or not success then
    error("Mason registry refresh failed; check GitHub/network access")
  end
  -- Resolve package names from this exact locked mason-lspconfig version.
  local mapping = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
  local opts = LazyVim.opts("nvim-lspconfig")
  local names = { stylua = true, shfmt = true, ["tree-sitter-cli"] = true }
  for server, config in pairs(opts.servers) do
    if server ~= "*" and mapping[server] and config ~= false
      and not (type(config) == "table" and (config.enabled == false or config.mason == false)) then
      names[mapping[server]] = true
    end
  end
  local pending, failures = 0, {}
  for name in pairs(names) do
    local pkg = registry.get_package(name)
    if not pkg:is_installed() then
      pending = pending + 1
      pkg:once("install:success", function() pending = pending - 1 end)
      pkg:once("install:failed", function() pending = pending - 1; failures[#failures + 1] = name end)
      pkg:install()
    end
  end
  if not vim.wait(600000, function() return pending == 0 end, 200) then error("Mason installation timed out; inspect :Mason") end
  if #failures > 0 then error("Mason packages failed: " .. table.concat(failures, ", ")) end
  print("Plugin tools and language servers installed")
end
function M.main()
  checked(M.run)
end
return M
