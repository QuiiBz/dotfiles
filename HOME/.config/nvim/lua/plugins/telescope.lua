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
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  }
}

require('telescope').load_extension('fzf')
