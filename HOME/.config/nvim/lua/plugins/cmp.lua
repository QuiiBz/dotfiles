return {
  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    version = '*',
    opts = {
      keymap = {
        preset = 'none',
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<C-N>'] = { 'select_next', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-P>'] = { 'select_prev', 'fallback' },
        ['<Enter>'] = { 'accept', 'fallback' },
        ['<C-Space>'] = { 'show', 'fallback' },
        ['<Tab>'] = {
          function() -- sidekick next edit suggestion
            return require('sidekick').nes_jump_or_apply()
          end,
          'fallback',
        },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'buffer', 'path' },
      },
      completion = {
        menu = {
          winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
          border = 'rounded',
          draw = {
            columns = {
              { 'kind_icon' },
              { 'label', 'label_description', gap = 1 },
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
    opts_extend = { 'sources.default' },
  },
}
