return {
  dir = vim.fn.stdpath("data") .. "/plugins/conform.nvim",

  config = function()
    require("conform").setup({
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        python = { "black" },
      },

      default_format_opts = {
        timeout_ms = 3000,
        lsp_format = "fallback",
      },
    })
  end,
}
