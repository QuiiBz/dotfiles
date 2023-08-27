return {
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = { 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path' },
    config = function()
      local cmp = require('cmp')

      cmp.setup({
        snippet = {
          expand = function(args)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
        }, {
            { name = 'buffer' },
          }, {
            { name = 'path' },
          }),
        completion = {
          completeopt = 'menu,menuone,noinsert',
        }
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      -- cmp.setup.cmdline({ '/', '?' }, {
      --   mapping = cmp.mapping.preset.cmdline(),
      --   sources = {
      --     { name = 'buffer' }
      --   }
      -- })
    end
  }
}
