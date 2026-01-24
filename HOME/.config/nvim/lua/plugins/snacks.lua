local preview_layout = {
  layout = {
    box = 'vertical',
    backdrop = false,
    row = -1,
    width = 0,
    height = 0.5,
    border = 'top',
    title = ' {title} {live} {flags}',
    title_pos = 'left',
    { win = 'input', height = 1, border = 'bottom' },
    {
      box = 'horizontal',
      { win = 'list', border = 'none' },
      { win = 'preview', title = '{preview}', width = 0.4, border = 'left' },
    },
  },
}

local list_layout = {
  layout = {
    box = 'vertical',
    backdrop = false,
    row = -1,
    width = 0,
    height = 8,
    border = 'top',
    title = ' {title} {live} {flags}',
    title_pos = 'left',
    { win = 'input', height = 1, border = 'bottom' },
    { win = 'list', height = 0, border = 'none' },
  },
}

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    keys = {
      {
        '<C-p>',
        function()
          Snacks.picker.files({ hidden = true, layout = preview_layout })
        end,
      },
      {
        '<C-f>',
        function()
          Snacks.picker.grep({ hidden = true, regex = false, layout = preview_layout })
        end,
      },
      {
        'z=',
        function()
          Snacks.picker.spelling({ layout = list_layout })
        end,
      },
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
        sources = {
          select = {
            layout = list_layout,
          },
        },
        matcher = {
          fuzzy = true,
          smartcase = true,
          frecency = true,
        },
        win = {
          input = {
            keys = {
              ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
              ['<S-Tab>'] = { 'select_and_prev', mode = { 'i', 'n' } },
              ['<Tab>'] = { 'select_and_next', mode = { 'i', 'n' } },
            },
          },
        },
        formatters = {
          file = {
            truncate = 90, -- default is 60
          },
        },
      },
    },
  },
}
