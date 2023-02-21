vim.cmd([[nnoremap <C-n> :NvimTreeToggle<cr>]])

require("nvim-tree").setup({
  view = {
    width = 36,
  },
  renderer = {
    icons = {
      git_placement = 'after',
      show = {
        folder_arrow = false,
      }
    }
  },
  diagnostics = {
    enable = true,
  },
  filters = {
    dotfiles = true,
  },
})

