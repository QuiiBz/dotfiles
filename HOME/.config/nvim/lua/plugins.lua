return {
  -- Themes
  {
    'catppuccin/nvim',
    priority = 1000,
    config = function()
      require('catppuccin').setup({
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        transparent_background = true,
        float = {
          transparent = true,
        },
        integrations = {
          cmp = true,
          gitsigns = {
            enabled = true,
            transparent = true,
          },
          nvimtree = true,
          treesitter = true,
          fidget = true,
          mason = true,
          render_markdown = true,
          snacks = {
            enabled = true,
          },
          grug_far = true,
        },
      })
      vim.cmd.colorscheme('catppuccin')
    end,
  },
  -- Others
  {
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    config = function()
      require('nvim-ts-autotag').setup()
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup()
    end,
  },
  {
    'j-hui/fidget.nvim',
    tag = 'v1.6.1',
    event = 'LspAttach',
    config = function()
      require('fidget').setup({
        notification = {
          window = {
            winblend = 0,
          },
        },
        integration = {
          ['nvim-tree'] = {
            enable = false,
          },
        },
      })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('gitsigns').setup({
        preview_config = {
          border = 'rounded',
        },
      })
    end,
  },
  {
    'folke/persistence.nvim',
    config = function()
      if vim.fn.argc() > 0 then
        return
      end
      require('persistence').setup()
      require('persistence').load()
    end,
  },
  {
    'MagicDuck/grug-far.nvim',
    keys = {
      { '<leader>S', '<cmd>GrugFar<cr>' },
    },
    config = function()
      require('grug-far').setup({
        debounceMs = 100,
        enabledEngines = { 'rg' },
        showCompactInputs = true,
        showStatusIcon = false,
        showEngineInfo = false,
        transient = true,
        folding = {
          enabled = false,
        },
        resultLocation = {
          showNumberLabel = false,
        },
      })
    end,
  },
  {
    'tversteeg/registers.nvim',
    keys = {
      { '"', mode = { 'n', 'v' } },
    },
    config = function()
      require('registers').setup({
        window = {
          border = 'rounded',
          transparency = 0,
        },
      })
    end,
  },
  {
    'aznhe21/actions-preview.nvim',
    keys = {
      { 'ga', '<cmd>lua require("actions-preview").code_actions()<cr>' },
    },
    config = function()
      local hl = require('actions-preview.highlight')
      require('actions-preview').setup({
        backend = { 'snacks' },
        highlight_command = {
          hl.delta('delta --file-style=omit --paging=never'),
        },
        snacks = {
          layout = {
            preset = 'dropdown',
          },
        },
      })
    end,
  },
  {
    'laytan/cloak.nvim',
    event = { 'BufReadPre *.env' },
    config = function()
      require('cloak').setup()
    end,
  },
  {
    'folke/ts-comments.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
  },
  {
    'dstein64/nvim-scrollview',
    event = { 'BufReadPre', 'BufNewFile' },
    after = 'gitsigns.nvim',
    config = function()
      require('scrollview').setup({
        current_only = true,
        signs_on_startup = { 'diagnostics', 'folds', 'search' },
      })
      require('scrollview.contrib.gitsigns').setup()
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {
      file_types = { 'markdown' },
      preset = 'lazy',
      code = {
        language_icon = false,
        language_name = false,
        disable_background = true,
      },
    },
    ft = { 'markdown' },
  },
  {
    'QuiiBz/pretty-quickfix.nvim',
    -- dir = '~/dev/pretty-quickfix.nvim',
    dependencies = { 'nvim-web-devicons' },
    ft = { 'qf' },
    opts = {},
  },
}
