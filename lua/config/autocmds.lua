local group = vim.api.nvim_create_augroup("local_developer_workflow", { clear = true })

-- Prose benefits from wrapping and spelling; source code remains soft-wrapped
-- globally but never gets automatic hard line breaks.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "en_us" }
    vim.opt_local.conceallevel = 2
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})
