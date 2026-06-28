return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          component_separators = '  ',
          globalstatus = true,
          theme = 'catppuccin-nvim',
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            {
              'filename',
              file_status = false,
              path = 1,
            },
          },
          lualine_x = {
            'searchcount',
            -- Show macro recording status
            function()
              local reg = vim.fn.reg_recording()
              if reg == '' then
                return ''
              end
              return '@' .. reg
            end,
          },
          lualine_y = {},
          lualine_z = {},
        },
        inactive_sections = {},
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
      })
    end,
  },
}
