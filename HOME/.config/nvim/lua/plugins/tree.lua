vim.cmd([[nnoremap <C-n> :NvimTreeToggle<cr>]])

require("nvim-tree").setup({
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

