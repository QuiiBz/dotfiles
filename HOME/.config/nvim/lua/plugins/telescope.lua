return {
  {
    'nvim-telescope/telescope.nvim', branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
      }
    },
    keys = { '<C-p>', '<C-f>' },
    config = function()
      local telescope = require('telescope')
      local actions = require('telescope.actions')
      local builtin = require('telescope.builtin')

      vim.keymap.set('n', '<C-p>', builtin.git_files, {})
      vim.keymap.set('n', '<C-f>', builtin.live_grep, {})

      telescope.setup{
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

      telescope.load_extension('fzf')
    end
  },
}
