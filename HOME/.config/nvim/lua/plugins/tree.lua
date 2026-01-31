return {
  {
    'echasnovski/mini.files',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      {
        '<C-n>',
        function()
          -- Close or open based on the current file path
          if not MiniFiles.close() then
            MiniFiles.open(vim.api.nvim_buf_get_name(0))
          end
          MiniFiles.reveal_cwd()
        end,
      },
    },
    config = function()
      local show_dotfiles = false
      local filter_show = function()
        return true
      end
      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, '.')
      end
      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        MiniFiles.refresh({ content = { filter = new_filter } })
      end

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

      -- Use '.' to toggle dotfiles visibility (off by default)
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set('n', '.', toggle_dotfiles, { buffer = buf_id })
        end,
      })

      -- Remember if we wanted to hide/show dotfiles after re-opening
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesExplorerOpen',
        callback = function()
          local new_filter = show_dotfiles and filter_show or filter_hide
          MiniFiles.refresh({ content = { filter = new_filter } })
        end,
      })

      -- Rounded borders
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesWindowOpen',
        callback = function(args)
          local win_id = args.data.win_id
          local config = vim.api.nvim_win_get_config(win_id)
          config.border = 'rounded'
          vim.api.nvim_win_set_config(win_id, config)
        end,
      })

      -- LSP-integrated file renaming
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesActionRename',
        callback = function(event)
          Snacks.rename.on_rename_file(event.data.from, event.data.to)
        end,
      })
    end,
  },
}
