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
        Snacks.picker.grep({ hidden = true, layout = { preset = 'telescope' } })
      end },
    },
    opts = {
      lazygit = {
        enabled = true,
        configure = false,
      },
      bigfile = {
        enabled = true,
        notify = false,
        size = 1024 * 300, -- 300kB
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
        formatters = {
          file = {
            truncate = 90, -- default is 60
          },
        }
      },
    },
  },
}
