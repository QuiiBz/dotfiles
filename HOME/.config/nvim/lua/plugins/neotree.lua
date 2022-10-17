-- Unless you are still migrating, remove the deprecated commands from v1.x
vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])
-- Toggle with CTRL+N
vim.cmd([[nnoremap <C-n> :Neotree toggle<cr>]])


require('neo-tree').setup({
  popup_border_style = 'rounded',
  enable_git_status = true,
  enable_diagnostics = true,
  default_component_configs = {
    indent = {
      padding = 0,
    },
    modified = {
      symbol = '',
    },
    name = {
      use_git_status_colors = false,
    },
    git_status = {
      symbols = {
        -- Change type
        added     = "✚", -- or "✚", but this is redundant info if you use git_status_colors on the name
        modified  = "", -- or "", but this is redundant info if you use git_status_colors on the name
        deleted   = "✖",-- this can only be used in the git_status source
        renamed   = "",-- this can only be used in the git_status source
        -- Status type
        untracked = "",
        ignored   = "",
        unstaged  = "",
        staged    = "",
        conflict  = "",
      }
    },
  },
  window = {
    mappings = {
      ['/'] = 'noop',
    },
  },
  filesystem = {
    follow_current_file = true,
  },
  buffers=  {
    follow_current_file = true,
  },
})

