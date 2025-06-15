return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    keys = {
      { '<C-p>', function()
        Snacks.picker.files({ hidden = true, layout = { preset = 'telescope' } })
      end },
      { '<C-f>', function()
        Snacks.picker.grep({ layout = { preset = 'telescope' } })
      end },
    },
    opts = {
      lazygit = {
        enabled = true,
        configure = false,
      },
      bigfile = {
        enabled = true,
        size = 1024 * 300, -- 300kB
      },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { key = 's', icon = ' ', desc = 'Load session (directory)', action = ':lua require("persistence").load()' },
            { key = 'l', icon = ' ', desc = 'Load last session', action = ':lua require("persistence").load({ last = true })' },
            { key = 'f', icon = ' ', desc = 'Find files', action = ':lua Snacks.picker.files({ hidden = true, layout = { preset = "telescope" } })' },
            { key = 'r', icon = ' ', desc = 'Search in files', action = ':lua Snacks.picker.grep({ layout = { preset = "telescope" } })' },
          },
          header = '',
        },
        sections = {
          { section = 'keys',   gap = 1, padding = 3 },
          { section = 'startup' },
        },
      },
      picker = {
        matcher = {
          fuzzy = true,
          smartcase = true,
          frecency = true,
        },
        win = {
          input = {
            keys = {
              ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
            },
          },
        },
      },
    },
  },
}
