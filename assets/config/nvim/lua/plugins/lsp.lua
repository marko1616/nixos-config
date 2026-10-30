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

    -- clangd sends parameter-name and deduced-type hints; show them so calls
    -- can be filled without relying on placeholder text.
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(ev)
        if vim.lsp.inlay_hint then
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
      end,
    })
  end,
}
