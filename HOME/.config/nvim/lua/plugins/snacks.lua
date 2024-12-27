return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      lazygit = {
        enabled = true,
        configure = false,
      },
      bigfile = {
        enabled = true,
        size = 1024 * 100, -- 100kB
      },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { key = 's', icon = ' ', desc = 'Load session (directory)', action = ':lua require("persistence").load()' },
            { key = 'l', icon = ' ', desc = 'Load last session', action = ':lua require("persistence").load({ last = true })' },
            { key = 'f', icon = ' ', desc = 'Find files', action = ':lua require("telescope.builtin").git_files({ silent = true })' },
            { key = 'r', icon = ' ', desc = 'Search in files', action = ':lua require("telescope.builtin").live_grep({ silent = true })' },
          },
          header = '',
        },
        sections = {
          { section = 'header' },
          { section = 'keys',   gap = 1, padding = 3 },
          { section = 'startup' },
        },
      },
    },
  },
}
