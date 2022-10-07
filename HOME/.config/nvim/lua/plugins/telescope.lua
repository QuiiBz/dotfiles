local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<C-p>', builtin.find_files, {})
vim.keymap.set('n', '<C-f>', builtin.live_grep, {})

require('telescope').setup{
  defaults = {
    mappings = {
      i = {
        ['<esc>'] = actions.close
      },
    },
  }
}
