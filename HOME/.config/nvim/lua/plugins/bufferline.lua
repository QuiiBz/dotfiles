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
              tab = { bg = C.base },
              tab_selected = { bg = C.base },
              tab_separator = { bg = C.base },
              tab_separator_selected = { bg = C.base },
              tab_close = { bg = C.base },
              close_button = { bg = C.base },
              close_button_visible = { bg = C.base },
              close_button_selected = { bg = C.base },
              buffer_visible = { bg = C.base },
              buffer_selected = { bg = C.base },
              numbers = { bg = C.base },
              numbers_visible = { bg = C.base },
              numbers_selected = { bg = C.base },
              diagnostic = { bg = C.base },
              diagnostic_visible = { bg = C.base },
              diagnostic_selected = { bg = C.base },
              hint = { bg = C.base },
              hint_visible = { bg = C.base },
              hint_selected = { bg = C.base },
              hint_diagnostic = { bg = C.base },
              hint_diagnostic_visible = { bg = C.base },
              hint_diagnostic_selected = { bg = C.base },
              info = { bg = C.base },
              info_visible = { bg = C.base },
              info_selected = { bg = C.base },
              info_diagnostic = { bg = C.base },
              info_diagnostic_visible = { bg = C.base },
              info_diagnostic_selected = { bg = C.base },
              warning = { bg = C.base },
              warning_visible = { bg = C.base },
              warning_selected = { bg = C.base },
              warning_diagnostic = { bg = C.base },
              warning_diagnostic_visible = { bg = C.base },
              warning_diagnostic_selected = { bg = C.base },
              error = { bg = C.base },
              error_visible = { bg = C.base },
              error_selected = { bg = C.base },
              error_diagnostic = { bg = C.base },
              error_diagnostic_visible = { bg = C.base },
              error_diagnostic_selected = { bg = C.base },
              modified = { bg = C.base },
              modified_visible = { bg = C.base },
              modified_selected = { bg = C.base },
              duplicate_selected = { bg = C.base },
              duplicate_visible = { bg = C.base },
              duplicate = { bg = C.base },
              separator_selected = { bg = C.base },
              separator_visible = { bg = C.base },
              separator = { bg = C.base },
              indicator_visible = { bg = C.base },
              indicator_selected = { bg = C.base },
              pick_selected = { bg = C.base },
              pick_visible = { bg = C.base },
              pick = { bg = C.base },
              offset_separator = { bg = C.base },
              trunc_marker = { bg = C.base }
            }
          }
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
