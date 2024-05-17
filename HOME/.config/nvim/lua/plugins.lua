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
    tag = 'legacy',
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
  'kdheepak/lazygit.nvim',
  {
    'github/copilot.vim',
    event = 'InsertEnter',
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
    config = function()
      require('registers').setup({
        window = {
          border = 'rounded',
        },
      })
    end
  },
  {
    'weilbith/nvim-code-action-menu',
    keys = {
      { 'ga', '<cmd>CodeActionMenu<cr>' }
    },
    init = function()
      vim.g.code_action_menu_window_border = 'rounded'
      vim.g.code_action_menu_show_action_kind = false
      vim.g.code_action_menu_show_details = false
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
    'chrishrb/gx.nvim',
    keys = { 'gx' },
    config = function()
      require('gx').setup()
    end
  }
}
