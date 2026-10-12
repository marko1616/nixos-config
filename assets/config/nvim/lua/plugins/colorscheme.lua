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
          if type(value) == "table" and type(colors[name]) == "table" and value[1] == nil then
            for child_name, child_value in pairs(value) do
              colors[name][child_name] = child_value
            end
          else
            colors[name] = value
          end
        end
        -- The plugin captures these before on_colors; later highlight blends
        -- must use the replacement background and foreground as well.
        local util = require("tokyonight.util")
        util.bg = colors.bg
        util.fg = colors.fg
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
