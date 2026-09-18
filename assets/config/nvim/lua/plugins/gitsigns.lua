return {
    dir =
        vim.fn.stdpath("data")
        .. "/plugins/gitsigns.nvim",

    config = function()

        require("gitsigns").setup({})

    end,
}
