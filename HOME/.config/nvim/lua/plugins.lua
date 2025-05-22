return {
  -- Themes
  {
    'catppuccin/nvim',
    config = function()
      require('catppuccin').setup({
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          -- fidget = true,
          mason = true,
          telescope = {
            enabled = true,
          },
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
    tag = 'v1.6.0',
    event = 'LspAttach',
    config = function()
      require('fidget').setup({
        text = {
          spinner = 'arc',
        },
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
    'nvim-pack/nvim-spectre',
    keys = {
      { '<leader>S', '<cmd>lua require("spectre").toggle()<cr>' }
    },
    dependencies = { 'nvim-lua/plenary.nvim' }
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
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.4,
            height = 0.4,
            prompt_position = "top",
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
        winblend = 100,
        width = 1,
      })
    end
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {
      file_types = { 'markdown', 'Avante' },
      preset = 'lazy',
      code = {
        language_icon = false,
        language_name = false,
        disable_background = true,
      },
    },
    ft = { 'markdown', 'Avante' },
  },
}
