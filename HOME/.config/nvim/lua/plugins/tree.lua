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

      local show_dotfiles = false
      local filter_show = function(fs_entry) return true end
      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, '.')
      end
      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        MiniFiles.refresh({ content = { filter = new_filter } })
      end

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set('n', '.', toggle_dotfiles, { buffer = buf_id })
        end,
      })
    end
  },
}
