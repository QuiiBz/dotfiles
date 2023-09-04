return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'linrongbin16/lsp-progress.nvim',
    },
    config = function()
      require('lualine').setup({
        options = {
          component_separators = '|',
          section_separators = { left = '', right = '' },
          globalstatus = true,
          theme = 'catppuccin',
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = { 'diff' },
          lualine_x = {},
          lualine_y = { 'filetype' },
          lualine_z = { 'progress' }
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
