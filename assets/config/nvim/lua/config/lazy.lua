local data = vim.fn.stdpath("data")
local state = vim.fn.stdpath("state")

vim.opt.rtp:prepend(data .. "/plugins/lazy.nvim")

require("lazy").setup({
  { import = "plugins" },
}, {
  root = data .. "/lazy",
  lockfile = state .. "/lazy-lock.json",

  install = {
    missing = false,
  },

  checker = {
    enabled = false,
  },
})
