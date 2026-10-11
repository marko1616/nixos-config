return {
  dir = vim.fn.stdpath("data")
    .. "/plugins/tokyonight.nvim",

  lazy = false,
  priority = 1000,

  config = function()
    local generated = require("theme.colors")
    require("tokyonight").setup({
      transparent = true,

      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },

      on_colors = function(colors)
        for name, value in pairs(generated.palette) do
          if name == "git" then
            for git_name, git_value in pairs(value) do
              colors.git[git_name] = git_value
            end
          else
            colors[name] = value
          end
        end
      end,

      on_highlights = function(hl, _)
        for group, value in pairs(generated.highlights) do
          hl[group] = value
        end
      end,
    })

    vim.cmd.colorscheme("tokyonight-night")
  end,
}
