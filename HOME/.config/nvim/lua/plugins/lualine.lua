return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          component_separators = '',
          section_separators = { left = '', right = '' },
          globalstatus = true,
          theme = 'catppuccin',
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {},
          lualine_c = {
            {
              'filename',
              path = 1,
            },
            'diff',
          },
          lualine_x = { 'searchcount' },
          lualine_y = {},
          lualine_z = {}
        },
        inactive_sections = {},
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      })
    end,
  }
}
