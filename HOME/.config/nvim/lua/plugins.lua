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
    'linrongbin16/lsp-progress.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lsp-progress').setup()
    end
  },
  { 'akinsho/bufferline.nvim', version = 'v2.*' },
  {
  'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end
  },
  'kdheepak/lazygit.nvim',
  'github/copilot.vim',
  {
  'folke/persistence.nvim',
    event = 'BufReadPre',
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
