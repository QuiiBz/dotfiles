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
      cmdline = {
        sources = {},
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
              { "kind_icon" },
              { "label",    "label_description", gap = 1 },
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
}
