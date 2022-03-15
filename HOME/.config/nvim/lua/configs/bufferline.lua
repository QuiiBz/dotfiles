require'bufferline'.setup {
  options = {
    show_buffer_close_icons = false,
    show_close_icon = false,
    separator_style = { '', '' },
    offsets = {
      {
        filetype = "NvimTree",
        text = ""
      }
    },
    diagnostics = 'nvim_lsp',
  }
}

