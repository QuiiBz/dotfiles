return {
  -- Themes
  {
    'catppuccin/nvim',
    config = function()
    require('catppuccin').setup({
      flavour = 'macchiato' -- latte, frappe, macchiato, mocha
    })
    vim.cmd.colorscheme "catppuccin"
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
  'numToStr/Comment.nvim',
    config = function()
    require('Comment').setup({
      pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
    })
  end
  },
  {
    'j-hui/fidget.nvim',
    tag = 'legacy',
    event = 'LspAttach',
    config = function()
      require('fidget').setup()
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('gitsigns').setup()
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
    keys = { '<leader>S' },
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
}
