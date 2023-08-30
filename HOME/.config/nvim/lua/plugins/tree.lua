return {
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<C-n>', '<cmd>NvimTreeToggle<cr>' }
    },
    config = function()
      require('nvim-tree').setup({
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
        update_focused_file = {
          enable = true,
        },
        diagnostics = {
          enable = true,
        },
        filters = {
          dotfiles = true,
        },
      })
    end
  }
}

