local M = {}

local root_markers = {
  ".git", ".codex", "package.json", "pyproject.toml", "Cargo.toml", "go.mod",
  "compose.yaml", "compose.yml", "docker-compose.yml", "Dockerfile",
}

local function project_root()
  local buffer_path = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(buffer_path ~= "" and buffer_path or 0, root_markers) or vim.fn.getcwd()
end

local function executable()
  local path = vim.fn.exepath("lazygit")
  if path ~= "" then return path end

  -- WinGet's portable package sometimes is not added to PATH until the next
  -- sign-in. Discover its stable package location so LazyGit works right away.
  local local_app_data = vim.env.LOCALAPPDATA
  if local_app_data then
    local matches = vim.fn.glob(
      local_app_data .. "/Microsoft/WinGet/Packages/JesseDuffield.lazygit_*/lazygit.exe",
      false,
      true
    )
    if #matches > 0 and vim.fn.executable(matches[1]) == 1 then return matches[1] end
  end
end

function M.open()
  local lazygit = executable()
  if not lazygit then
    vim.notify("LazyGit is not installed. Run: winget install -e --id=JesseDuffield.lazygit", vim.log.levels.ERROR)
    return
  end

  require("lazy").load({ plugins = { "snacks.nvim" } })
  require("snacks").terminal.focus({ lazygit }, {
    cwd = project_root(),
    win = {
      position = "float",
      width = 0.94,
      height = 0.90,
      border = "rounded",
      title = " 󰊢  LazyGit ",
      title_pos = "center",
      wo = {
        winblend = 0,
        wrap = false,
        cursorline = false,
        number = false,
        relativenumber = false,
        signcolumn = "no",
      },
    },
  })
end

return M
