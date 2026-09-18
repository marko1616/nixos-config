local plugins = vim.fn.stdpath("data") .. "/plugins"

return {
  dir = plugins .. "/nvim-lspconfig",

  dependencies = {
    { dir = plugins .. "/cmp-nvim-lsp" },
  },

  config = function()
    local capabilities =
      require("cmp_nvim_lsp").default_capabilities()

    for _, server in ipairs({ "clangd", "pyright" }) do
      vim.lsp.config(server, {
        capabilities = capabilities,
      })

      vim.lsp.enable(server)
    end
  end,
}
