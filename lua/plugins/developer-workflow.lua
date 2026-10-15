return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante", "codecompanion" },
    opts = {
      heading = { enabled = true, sign = false },
      code = { sign = false, width = "block" },
      checkbox = { enabled = true },
      callout = { note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" } },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      keymap = { preset = "enter" },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 250 }, ghost_text = { enabled = true } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        enabled = true,
        -- Keep the lightweight Windows shell for generic terminal commands.
        -- :Nushell still launches `nu` directly, so this does not change the
        -- dedicated Nushell workflow or make Codex start through an extra shell.
        shell = require("config.machine").shell,
        -- Do not inherit editor display settings in terminal buffers. In
        -- particular, `wrap` makes full-screen TUIs (Codex included) redraw
        -- and position their cursor much more slowly on Windows.
        win = {
          wo = {
            wrap = false,
            linebreak = false,
            breakindent = false,
            cursorline = false,
            number = false,
            relativenumber = false,
            signcolumn = "no",
            scrolloff = 0,
            sidescrolloff = 0,
          },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {},
        nushell = {},
        dockerls = {},
        docker_compose_language_service = {},
        yamlls = {},
        marksman = {},
        jsonls = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "c",
        "cpp",
        "nu",
        "dockerfile",
        "markdown",
        "markdown_inline",
      },
    },
  },
}
