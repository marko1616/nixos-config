return {
  dir = vim.fn.stdpath("data")
    .. "/plugins/lualine.nvim",

  dependencies = {
    {
      dir = vim.fn.stdpath("data")
        .. "/plugins/nvim-web-devicons",
    },
  },

  config = function()
    require("lualine").setup({
      options = {
        theme = "tokyonight",
      },
    })
  end,
}
