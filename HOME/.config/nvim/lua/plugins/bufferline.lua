return {
  {
    'akinsho/bufferline.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    after = 'catppuccin',
    config = function()
      local bufferline = require('bufferline')
      local selected_bg = '#34364B'
      local accent_fg = '#c6a0f6'
      bufferline.setup({
        highlights = require('catppuccin.special.bufferline').get_theme({
          styles = { 'bold' },
          custom = {
            all = {
              buffer_selected = { bg = selected_bg },
              diagnostic_selected = { bg = selected_bg },
              error_selected = { bg = selected_bg },
              warning_selected = { bg = selected_bg },
              info_selected = { bg = selected_bg },
              hint_selected = { bg = selected_bg },
              error_diagnostic_selected = { bg = selected_bg },
              warning_diagnostic_selected = { bg = selected_bg },
              info_diagnostic_selected = { bg = selected_bg },
              hint_diagnostic_selected = { bg = selected_bg },
              duplicate_selected = { bg = selected_bg },
              modified = { fg = accent_fg },
              modified_selected = { fg = accent_fg, bg = selected_bg },
              close_button_selected = { bg = selected_bg },
              indicator_selected = { fg = accent_fg, bg = selected_bg },
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
          tab_size = 10,
          close_command = function(bufnr)
            if bufnr == vim.api.nvim_get_current_buf() then
              vim.cmd('BufferLineCycleNext')
            end
            vim.cmd('bdelete ' .. bufnr)
          end,
        },
      })
    end,
  },
}
