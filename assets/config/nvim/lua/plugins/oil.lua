return {
    dir =
        vim.fn.stdpath("data")
        .. "/plugins/oil.nvim",

    config = function()

        require("oil").setup({})

    end,
}
