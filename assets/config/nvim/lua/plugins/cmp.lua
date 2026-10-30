local plugins = vim.fn.stdpath("data") .. "/plugins"

return {
  dir = plugins .. "/nvim-cmp",

  dependencies = {
    { dir = plugins .. "/cmp-nvim-lsp" },
    { dir = plugins .. "/LuaSnip" },
    { dir = plugins .. "/cmp_luasnip" },
  },

  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),

        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),

        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),

        ["<CR>"] = cmp.mapping.confirm({
          select = false,
        }),

        -- An active snippet session wins over the completion menu: clangd
        -- inserts the whole signature as placeholders, so <Tab>/<S-Tab> must
        -- move between parameters while a popup may still be open. Menu
        -- selection stays on <C-n>/<C-p>. Same order as Neovim 0.11's builtin
        -- snippet mappings and blink.cmp's "super-tab" preset.
        ["<Tab>"] = cmp.mapping(function(fallback)
          if luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          elseif cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          elseif cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      }),

      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip" },
      },
    })
  end,
}
