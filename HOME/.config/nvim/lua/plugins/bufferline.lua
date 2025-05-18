return {
  {
    'akinsho/bufferline.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    after = 'catppuccin',
    config = function()
      local C = require('catppuccin.palettes').get_palette()

      require('bufferline').setup({
        highlights = require('catppuccin.groups.integrations.bufferline').get({
          custom = {
            all = {
              -- Overwrite the background colors to be the same as all backgrounds
              fill = { bg = C.base },
              background = { bg = C.base },
              buffer_visible = { bg = C.base },
              indicator_visible = { bg = C.base },
              duplicate = { bg = C.base },
              duplicate_visible = { bg = C.base },
              duplicate_selected = { bg = C.base },
              info = { bg = C.base },
              warning = { bg = C.base },
              error = { bg = C.base },
            },
          },
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
    end
  }
}
