require'lualine'.setup {
  options = {
    theme = 'auto',
    -- section_separators = { left = '', right = ''},
    -- component_separators = { left = '', right = ''},
    section_separators = '',
    component_separators = '',
    disabled_filetypes = { 'NvimTree' }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff'},
    lualine_c = {'diagnostics', 'filename'},
    lualine_x = { 'encoding' },
    lualine_y = {'filetype'},
    lualine_z = {'progress'},
  },
}

