-- Copy to local.lua in the installed config; local.lua is ignored by Git.
return {
  -- Desktop-bundled Codex on the original machine uses this flag.
  -- Leave {} for a CLI that does not support --no-daemon.
  codex_args = { "--no-daemon" },
  docker = {
    enabled = true,
    container = "miivii_dev",
    host_root = "D:/workspace/src", -- Linux example: /home/you/workspace/src
    container_root = "/home/nvidia/workspace/src",
    clangd = "clangd-12", -- Must exist INSIDE the container.
    display = "host.docker.internal:0", -- Change for your Linux X11 setup.
  },
}
