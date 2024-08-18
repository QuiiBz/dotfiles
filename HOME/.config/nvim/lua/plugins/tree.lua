return {
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    -- keys = {
    --   { '<C-n>', '<cmd>NvimTreeToggle<cr>' }
    -- },
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
        filesystem_watchers = {
          enable = true,
          debounce_delay = 50,
          ignore_dirs = {
            "node_modules"
          },
        },
      })
    end
  },
  {
    'echasnovski/mini.files',
    version = '*',
    keys = {
      { '<C-n>', '<cmd>lua MiniFiles.open()<cr>' }
    },
    config = function()
      require('mini.files').setup({
        mappings = {
          go_in = '<Tab>',
          go_in_plus = '<Enter>',
          go_out = '<Esc>',
        },
        options = {
          permanent_delete = false,
        },
        windows = {
          preview = true,
          width_focus = 25,
          width_preview = 50,
        },
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesWindowOpen',
        callback = function(args)
          local win_id = args.data.win_id
          local config = vim.api.nvim_win_get_config(win_id)
          config.border = 'rounded'
          vim.api.nvim_win_set_config(win_id, config)
        end,
      })
    end
  },
}
