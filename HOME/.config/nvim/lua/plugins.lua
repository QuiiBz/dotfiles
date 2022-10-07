return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Dependencies
  use 'nvim-lua/plenary.nvim'
  use 'kyazdani42/nvim-web-devicons'
  use 'MunifTanjim/nui.nvim'

  -- Themes
  use {
    'catppuccin/nvim',
    as = 'catppuccin',
    config = function()
      vim.g.catppuccin_flavour = 'macchiato' -- latte, frappe, macchiato, mocha
      require('catppuccin').setup()
      vim.api.nvim_command 'colorscheme catppuccin'
    end
  }

  -- Other plugins
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  use {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v2.x',
  }
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
  }
  use {
    'windwp/nvim-ts-autotag',
    config = function()
      require('nvim-ts-autotag').setup()
    end
  }
  use {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup()
    end
  }
  use 'neovim/nvim-lspconfig'
  use {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end
  }
  use 'williamboman/mason-lspconfig.nvim'
  use 'jose-elias-alvarez/null-ls.nvim'
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup({
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      })
    end
  }
  use 'JoosepAlviste/nvim-ts-context-commentstring'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/nvim-cmp'
  use 'nvim-lualine/lualine.nvim'
  use {'akinsho/bufferline.nvim', tag = 'v2.*' }
  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end
  }
  use 'kdheepak/lazygit.nvim'

end)
