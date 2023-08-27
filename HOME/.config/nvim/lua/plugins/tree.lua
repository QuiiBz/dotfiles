return {
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    init = function()
      vim.cmd([[nnoremap <C-n> :NvimTreeToggle<cr>]])
    end,
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

