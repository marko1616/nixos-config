return {
  dir = vim.fn.stdpath("data")
    .. "/plugins/tokyonight.nvim",

  lazy = false,
  priority = 1000,

  config = function()
    require("tokyonight").setup({
      transparent = true,

      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },

      on_colors = function(colors)
        colors.bg_statusline = colors.none
      end,

      on_highlights = function(hl, colors)
        hl.LineNrAbove = {
          fg = colors.blue,
          bg = colors.none,
        }

        hl.LineNrBelow = {
          fg = colors.blue,
          bg = colors.none,
        }

        hl.CursorLineNr = {
          fg = colors.cyan,
          bg = colors.none,
          bold = true,
        }

        hl.LineNr = {
          fg = colors.blue,
          bg = colors.none,
        }
      end,
    })

    vim.cmd.colorscheme("tokyonight-night")
  end,
}
