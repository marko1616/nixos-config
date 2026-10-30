local map = vim.keymap.set

map("i", "<C-k>", function()
  vim.lsp.buf.signature_help()
end, {
  desc = "Signature help",
})

map({ "n", "v" }, "<leader>f", function()
  require("conform").format({
    async = true,
    lsp_format = "fallback",
  })
end, {
  desc = "Format buffer or selection",
})

-- Diagnostics: Trouble panels, line detail, and diagnostics-to-loclist.
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", {
  desc = "Diagnostics (Trouble)",
})
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", {
  desc = "Buffer diagnostics (Trouble)",
})
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", {
  desc = "Quickfix list (Trouble)",
})
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", {
  desc = "Location list (Trouble)",
})
map("n", "<leader>cd", vim.diagnostic.open_float, {
  desc = "Line diagnostics",
})
map("n", "<leader>cL", function()
  vim.diagnostic.setloclist()
  vim.cmd.lopen()
end, {
  desc = "Diagnostics to location list",
})
