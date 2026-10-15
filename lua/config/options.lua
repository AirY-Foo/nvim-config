-- Editor behaviour modelled after VS Code where it is useful in a terminal.
-- WinGet updates the user PATH, but already-open terminals keep the old PATH.
-- Make Treesitter immediately find the WinLibs GCC installed for this user.
if vim.fn.executable("gcc") == 0 then
  local local_app_data = vim.env.LOCALAPPDATA
  if local_app_data then
    local matches = vim.fn.glob(local_app_data .. "/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_*/mingw64/bin", false, true)
    if #matches > 0 and vim.fn.executable(matches[1] .. "/gcc.exe") == 1 then
      vim.env.PATH = matches[1] .. ";" .. vim.env.PATH
    end
  end
end

-- Same fallback for the Node.js LTS runtime used by Mason's npm packages.
if vim.fn.executable("node") == 0 and vim.env.ProgramFiles then
  local node_bin = vim.env.ProgramFiles .. "/nodejs"
  if vim.fn.executable(node_bin .. "/node.exe") == 1 then
    vim.env.PATH = node_bin .. ";" .. vim.env.PATH
  end
end

vim.opt.wrap = true
-- Use 24-bit colours so the warm foreground and richer syntax palette below
-- are not reduced to the limited colours of an old terminal palette.
vim.opt.termguicolors = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↳ "
vim.opt.breakindentopt = "shift:2,min:20"
vim.opt.textwidth = 0
vim.opt.colorcolumn = ""
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
