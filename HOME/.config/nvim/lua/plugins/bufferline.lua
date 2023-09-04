return {
  {
    'akinsho/bufferline.nvim',
    version = 'v2.*',
    event = { 'BufReadPre', 'BufNewFile' },
    after = 'catppuccin',
    config = function()
      require('bufferline').setup({
        highlights = require('catppuccin.groups.integrations.bufferline').get(),
        options = {
          show_buffer_close_icons = false,
          show_close_icon = false,
          separator_style = { '', '' },
          diagnostics = 'nvim_lsp',
        },
      })
    end
  }
}
