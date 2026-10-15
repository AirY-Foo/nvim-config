local workflow = require("config.codex")
local lazygit = require("config.lazygit")

vim.api.nvim_create_user_command("Codex", function(command) workflow.agent(command.args) end, {
  nargs = "*", desc = "Open Codex CLI in a side split (optional initial prompt)",
})
vim.api.nvim_create_user_command("CodexAsk", function(command)
  if command.args == "" then workflow.ask() else workflow.agent(command.args) end
end, { nargs = "*", desc = "Ask Codex about the current project" })
vim.api.nvim_create_user_command("CodexFix", workflow.fix_current_file, {
  desc = "Ask Codex for the smallest safe fix to the current file",
})
vim.api.nvim_create_user_command("CodexSelection", function(command)
  workflow.selection(command.line1, command.line2)
end, { range = true, desc = "Ask Codex to review the selected line range" })
vim.api.nvim_create_user_command("CodexReview", workflow.review, { desc = "Run Codex review for current changes" })
vim.api.nvim_create_user_command("CodexResume", workflow.resume, { desc = "Resume the most recent Codex CLI session" })
vim.api.nvim_create_user_command("CodexDoctor", workflow.doctor, { desc = "Run Codex CLI diagnostics" })
vim.api.nvim_create_user_command("CodexDiff", workflow.diff, { desc = "Show current Git diff summary" })
vim.api.nvim_create_user_command("Yazi", workflow.yazi, { desc = "Open Yazi in the current file directory" })
vim.api.nvim_create_user_command("LazyGit", lazygit.open, { desc = "Open LazyGit in the current project" })
vim.api.nvim_create_user_command("DockerComposeUp", function()
  workflow.compose("docker compose up --build", "Docker Compose: up")
end, { desc = "Build and start Docker Compose" })
vim.api.nvim_create_user_command("DockerComposeDown", function()
  workflow.compose("docker compose down", "Docker Compose: down")
end, { desc = "Stop Docker Compose" })
vim.api.nvim_create_user_command("DockerLogs", function()
  workflow.compose("docker compose logs -f --tail=150", "Docker Compose: logs")
end, { desc = "Follow Docker Compose logs" })
vim.api.nvim_create_user_command("DebDeploy", function(command)
  workflow.deploy_deb(command.fargs)
end, {
  nargs = "*",
  desc = "Upload a local .deb to an SSH host and install it with dpkg",
})
vim.api.nvim_create_user_command("Nushell", workflow.nushell, { desc = "Open Nushell terminal in project root" })
vim.api.nvim_create_user_command("DockerShell", function(command) workflow.container_shell(command.args) end, {
  nargs = "?", desc = "Choose and enter a Docker container ([container name])",
})
vim.api.nvim_create_user_command("MiiviiShell", workflow.miivii_shell, { desc = "Start/attach miivii_dev shell" })
vim.api.nvim_create_user_command("MiiviiLogs", workflow.miivii_logs, { desc = "Follow miivii_dev logs" })
vim.api.nvim_create_user_command("MiiviiCMakeConfigure", workflow.miivii_cmake_configure, {
  desc = "Configure CMake inside miivii_dev with ROS/catkin",
})
vim.api.nvim_create_user_command("MiiviiCMakeBuild", workflow.miivii_cmake_build, {
  desc = "Build CMake project inside miivii_dev",
})

-- Keep terminal shortcuts available before LazyVim's VeryLazy event.
vim.keymap.set("n", "<leader>tn", workflow.nushell, { desc = "Terminal: Nushell" })
vim.keymap.set("n", "<leader>ds", workflow.container_shell, { desc = "Docker: choose container shell" })
vim.keymap.set("n", "<leader>fy", workflow.yazi, { desc = "Files: Yazi" })
vim.keymap.set("n", "<leader>ms", workflow.miivii_shell, { desc = "miivii: shell" })
vim.keymap.set("n", "<leader>ml", workflow.miivii_logs, { desc = "miivii: logs" })
vim.keymap.set("n", "<leader>mc", workflow.miivii_cmake_configure, { desc = "miivii: CMake configure + compile database" })
vim.keymap.set("n", "<leader>mb", workflow.miivii_cmake_build, { desc = "miivii: CMake build" })
