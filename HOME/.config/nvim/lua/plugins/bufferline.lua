return {
  {
    'akinsho/bufferline.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    after = 'catppuccin',
    config = function()
      local bufferline = require('bufferline')
      bufferline.setup({
        highlights = require('catppuccin.special.bufferline').get_theme({
          styles = { 'bold' },
        }),
        options = {
          indicator = {
            style = 'none',
          },
          show_buffer_close_icons = false,
          show_tab_indicators = false,
          show_close_icon = false,
          separator_style = { '', '' },
          diagnostics = 'nvim_lsp',
          sort_by = 'insert_after_current',
        },
      })
    end,
  },
}
