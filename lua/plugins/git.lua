return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "]h", gs.next_hunk, "Git: next hunk")
        map("n", "[h", gs.prev_hunk, "Git: previous hunk")
        map("n", "<leader>ghs", gs.stage_hunk, "Git: stage hunk")
        map("v", "<leader>ghs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: stage selection")
        map("n", "<leader>ghr", gs.reset_hunk, "Git: reset hunk")
        map("n", "<leader>ghp", gs.preview_hunk, "Git: preview hunk")
        map("n", "<leader>ghb", function()
          gs.blame_line({ full = true })
        end, "Git: blame line")
        map("n", "<leader>ghd", gs.diffthis, "Git: diff file")
      end,
    },
  },
  {
    -- A full-screen Git TUI in a polished floating window.  Keeping this as a
    -- local integration (rather than another Neovim Git UI) means every
    -- LazyGit feature and its native key bindings remain available.
    "folke/snacks.nvim",
    keys = {
      { "<leader>gg", function() require("config.lazygit").open() end, desc = "Git: LazyGit" },
    },
  },
}
