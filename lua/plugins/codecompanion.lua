local args = require("config.machine").codex_args
return {
  {
    "olimorris/codecompanion.nvim",
    version = "*",
    cmd = {
      "CodeCompanion",
      "CodeCompanionActions",
      "CodeCompanionChat",
      "CodeCompanionCLI",
      "CodeCompanionCodeReview",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      interactions = {
        cli = {
          agent = "codex",
          agents = {
            codex = {
              cmd = "codex",
              args = vim.deepcopy(args),
              description = "OpenAI Codex CLI",
              provider = "terminal",
            },
            codex_resume = {
              cmd = "codex",
              args = vim.list_extend(vim.deepcopy(args), { "resume", "--last" }),
              description = "Resume the last Codex CLI session",
              provider = "terminal",
            },
            codex_doctor = {
              cmd = "codex",
              args = vim.list_extend(vim.deepcopy(args), { "doctor" }),
              description = "Codex CLI diagnostics",
              provider = "terminal",
            },
          },
          opts = {
            auto_insert = true,
            reload = true,
          },
        },
      },
      display = {
        cli = {
          window = {
            -- Run the real Codex TUI beside the source instead of in a float.
            layout = "vertical",
            position = "right",
            full_height = true,
            width = 0.42,
            opts = {
              number = false,
              relativenumber = false,
              signcolumn = "no",
              wrap = false,
            },
          },
        },
      },
    },
  },
}
