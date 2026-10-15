local map = vim.keymap.set
local workflow = require("config.codex")

-- Keep wrapped display lines intuitive, like VS Code's visual cursor movement.
map({ "n", "v" }, "j", "gj", { silent = true })
map({ "n", "v" }, "k", "gk", { silent = true })
map({ "n", "v" }, "0", "g0", { silent = true })
map({ "n", "v" }, "$", "g$", { silent = true })

-- LSP navigation works for both functions and variables under the cursor.
-- Keep the familiar Vim keys so these remain easy to use across languages.
map("n", "gd", vim.lsp.buf.definition, { desc = "LSP: go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "LSP: go to declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "LSP: find references" })
map("n", "gy", vim.lsp.buf.type_definition, { desc = "LSP: go to type definition" })
map("n", "K", vim.lsp.buf.hover, { desc = "LSP: show documentation" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP: rename symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: code actions" })

-- LazyVim also defines `gI`; installing this when a server attaches makes the
-- implementation jump win over Vim's built-in `gI` (insert at line start).
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    map("n", "gI", vim.lsp.buf.implementation, {
      buffer = event.buf,
      desc = "LSP: go to implementation",
    })
  end,
})

-- clangd understands matching .c/.cpp implementation and .h/.hpp declaration
-- files.  It is intentionally buffer-local, as other language servers do not
-- provide this extension command.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client or client.name ~= "clangd" then
      return
    end

    map("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", {
      buffer = event.buf,
      desc = "C/C++: switch source/header",
    })
  end,
})

map("n", "<leader>aa", function() workflow.agent("") end, { desc = "Codex: open agent" })
map("n", "<leader>ap", workflow.ask, { desc = "Codex: ask project question" })
map("n", "<leader>af", workflow.fix_current_file, { desc = "Codex: fix current file" })
map("v", "<leader>as", workflow.visual_selection, { desc = "Codex: selection actions" })
map("n", "<leader>ar", workflow.review, { desc = "Codex: review current changes" })
map("n", "<leader>ac", workflow.resume, { desc = "Codex: resume last session" })
map("n", "<leader>ad", workflow.diff, { desc = "Codex: show diff summary" })
map("n", "<leader>dd", function() workflow.compose("docker compose up --build", "Docker Compose: up") end, { desc = "Docker Compose up" })
map("n", "<leader>dx", function() workflow.compose("docker compose down", "Docker Compose: down") end, { desc = "Docker Compose down" })
map("n", "<leader>dl", function() workflow.compose("docker compose logs -f --tail=150", "Docker Compose: logs") end, { desc = "Docker Compose: logs" })
map("n", "<leader>ds", workflow.container_shell, { desc = "Docker: choose container shell" })
map("n", "<leader>tn", workflow.nushell, { desc = "Terminal: Nushell" })
map("n", "<leader>ms", workflow.miivii_shell, { desc = "miivii: shell" })
map("n", "<leader>ml", workflow.miivii_logs, { desc = "miivii: logs" })
