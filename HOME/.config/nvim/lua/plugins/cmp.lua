return {
  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    version = '*',
    opts = {
      keymap = {
        preset = 'none',
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<Enter>'] = { 'accept', 'fallback' },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono'
      },
      sources = {
        default = { 'lsp', 'buffer', 'path' },
        cmdline = {},
      },
      completion = {
        menu = {
          winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
          border = 'rounded',
          draw = {
            columns = {
              { "label",     "label_description", gap = 1 },
              { "kind_icon", "kind",              gap = 1 },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 0,
          window = { border = 'rounded' },
        },
      },
      signature = { window = { border = 'rounded' } },
    },
    opts_extend = { 'sources.default' }
  }
  -- {
  --   'hrsh7th/nvim-cmp',
  --   event = 'InsertEnter',
  --   dependencies = { 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path', 'onsails/lspkind.nvim' },
  --   config = function()
  --     local cmp = require('cmp')
  --     local lspkind = require('lspkind')
  --
  --     cmp.setup({
  --       snippet = {
  --         expand = function(args)
  --           vim.snippet.expand(args.body)
  --         end,
  --       },
  --       window = {
  --         completion = cmp.config.window.bordered(),
  --         documentation = cmp.config.window.bordered(),
  --       },
  --       mapping = cmp.mapping.preset.insert({
  --         ['<C-Space>'] = cmp.mapping.complete(),
  --         ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --       }),
  --       sources = cmp.config.sources({
  --         { name = 'nvim_lsp' },
  --       }, {
  --         { name = 'buffer' },
  --       }, {
  --         { name = 'path' },
  --       }),
  --       completion = {
  --         completeopt = 'menu,menuone,noinsert',
  --       },
  --       formatting = {
  --         format = lspkind.cmp_format({
  --           mode = 'symbol_text',
  --         })
  --       }
  --     })
  --
  --     -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  --     -- cmp.setup.cmdline({ '/', '?' }, {
  --     --   mapping = cmp.mapping.preset.cmdline(),
  --     --   sources = {
  --     --     { name = 'buffer' }
  --     --   }
  --     -- })
  --   end
  -- }
}
