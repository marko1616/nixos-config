return {
    dir =
        vim.fn.stdpath("data")
        .. "/plugins/trouble.nvim",

    config = function()

        require("trouble").setup({})

    end,
}
