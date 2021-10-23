local cmp = require'cmp'
local lspkind = require'lspkind'

cmp.setup({
  mapping = {
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'nvim_lua' },
    { name = 'luasnip' },
  }, {
    { name = 'path' },
    { name = 'buffer' },
  }),
  documentation = {
    border = 'single',
    maxwidth = 120,
    maxheight = math.floor(vim.o.lines * 0.3),
  },
  formatting = {
    format = lspkind.cmp_format({
      with_text = true,
      maxwidth = 50,
      menu = ({
        nvim_lsp = "LSP",
        nvim_lua = "Lua",
        luasnip = "Snip",
        path = "Path",
        buffer = "Buf",
      })
    })
  }
})

