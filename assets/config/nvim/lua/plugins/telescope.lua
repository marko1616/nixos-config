return {
    dir =
        vim.fn.stdpath("data")
        .. "/plugins/telescope.nvim",

    dependencies = {
        {
            dir =
                vim.fn.stdpath("data")
                .. "/plugins/plenary.nvim",
        },
    },

    config = function()

        require("telescope").setup({})

    end,
}
