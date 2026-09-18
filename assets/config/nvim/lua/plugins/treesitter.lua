return {
  dir = vim.fn.stdpath("data") .. "/plugins/nvim-treesitter",

  lazy = false,

  config = function()
    local treesitter = require("nvim-treesitter")

    if type(treesitter.setup) ~= "function"
      or type(treesitter.install) ~= "function"
    then
      error(
        "This configuration requires the rewritten "
          .. "nvim-treesitter API. Check the pinned plugin revision."
      )
    end

    treesitter.setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    local group = vim.api.nvim_create_augroup(
      "UserTreesitter",
      { clear = true }
    )

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = { "c", "cpp", "python", "lua", "nix" },

      callback = function(args)
        local ok, err = pcall(
          vim.treesitter.start,
          args.buf
        )

        if not ok then
          vim.notify_once(
            "Tree-sitter could not start: "
              .. tostring(err)
              .. "\nInstall the matching parser with :TSInstall.",
            vim.log.levels.WARN
          )
        end
      end,
    })
  end,
}
