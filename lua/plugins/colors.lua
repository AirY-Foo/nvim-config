return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = {
        transparent = true,
        solid = false,
      },
      term_colors = true,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = { "bold" },
        keywords = {},
        variables = {},
        strings = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
    },
    config = function(_, opts)
      local transparent_groups = {
        "Normal",
        "NormalNC",
        "NormalFloat",
        "FloatBorder",
        "SignColumn",
        "EndOfBuffer",
        "MsgArea",
        "SnacksNormal",
        "SnacksNormalNC",
      }

      local function apply_transparency()
        for _, group in ipairs(transparent_groups) do
          local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
          highlight.bg = nil
          highlight.ctermbg = nil
          vim.api.nvim_set_hl(0, group, highlight)
        end
      end

      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin-mocha")
      apply_transparency()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("transparent_background", { clear = true }),
        callback = apply_transparency,
        desc = "Keep editor and terminal windows transparent",
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
