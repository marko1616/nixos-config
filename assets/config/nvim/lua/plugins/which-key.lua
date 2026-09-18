return {
    dir =
        vim.fn.stdpath("data")
        .. "/plugins/which-key.nvim",

    config = function()

        require("which-key").setup({})

    end,
}
