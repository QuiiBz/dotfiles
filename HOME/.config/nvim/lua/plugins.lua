return {
  -- Themes
  {
    'catppuccin/nvim',
    config = function()
      require('catppuccin').setup({
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        transparent_background = true,
        float = {
          transparent = true
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
        }
      })
      vim.cmd.colorscheme 'catppuccin'
    end
  },
  -- Others
  {
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    config = function()
      require('nvim-ts-autotag').setup()
    end
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup()
    end
  },
  {
    'j-hui/fidget.nvim',
    tag = 'v1.6.1',
    event = 'LspAttach',
    config = function()
      require('fidget').setup({
        notification = {
          window = {
            winblend = 0
          }
        }
      })
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('gitsigns').setup({
        preview_config = {
          border = 'rounded',
        }
      })
    end
  },
  {
    'folke/persistence.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('persistence').setup()
    end,
  },
  {
    'MagicDuck/grug-far.nvim',
    keys = {
      { '<leader>S', '<cmd>GrugFar<cr>' }
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
    end
  },
  {
    'tversteeg/registers.nvim',
    keys = {
      { '\"',    mode = { 'n', 'v' } },
      { '<C-R>', mode = 'i' }
    },
    config = function()
      require('registers').setup({
        window = {
          border = 'rounded',
          transparency = 0,
        },
      })
    end
  },
  {
    'aznhe21/actions-preview.nvim',
    keys = {
      { 'ga', '<cmd>lua require("actions-preview").code_actions()<cr>' }
    },
    config = function()
      require('actions-preview').setup({
        snacks = {
          layout = {
            preset = 'dropdown',
          },
        },
      })
    end
  },
  {
    'laytan/cloak.nvim',
    event = { 'BufReadPre *.env' },
    config = function()
      require('cloak').setup()
    end
  },
  {
    'folke/ts-comments.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
  },
  {
    'lewis6991/satellite.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('satellite').setup({
        current_only = true,
        winblend = 0,
        width = 2,
      })
    end
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
    'catgoose/nvim-colorizer.lua',
    event = 'VeryLazy',
    opts = {
      lazy_load = true,
      user_commands = false,
      user_default_options = {
        names = false,
        RGB = true,
        RGBA = true,
        RRGGBB = true,
        RRGGBBAA = true,
        AARRGGBB = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
        tailwind = 'lsp',
        mode = 'virtualtext',
        virtualtext = '●',
      }
    },
  },
  {
    'QuiiBz/pretty-quickfix.nvim',
    -- dir = '~/dev/pretty-quickfix.nvim',
    dependencies = { 'nvim-web-devicons' },
    ft = { 'qf' },
    opts = {},
  },
}
