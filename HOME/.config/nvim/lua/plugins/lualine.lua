return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local C = require('catppuccin.palettes').get_palette()
      local theme = require('catppuccin.utils.lualine')()
      -- Overwrite the background color to be the same as all backgrounds
      theme.normal.c.bg = C.base

      require('lualine').setup({
        options = {
          component_separators = '',
          section_separators = { left = '', right = '' },
          globalstatus = true,
          theme = theme,
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
