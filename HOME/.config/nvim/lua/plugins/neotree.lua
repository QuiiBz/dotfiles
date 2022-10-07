-- Unless you are still migrating, remove the deprecated commands from v1.x
vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])
-- Toggle with CTRL+N
vim.cmd([[nnoremap <C-n> :Neotree toggle<cr>]])

require('neo-tree').setup({
  popup_border_style = 'rounded',
  enable_git_status = true,
  enable_diagnostics = true,
  filesystem = {
    follow_current_file = true,
  },
  buffers=  {
    follow_current_file = true,
  },
})

