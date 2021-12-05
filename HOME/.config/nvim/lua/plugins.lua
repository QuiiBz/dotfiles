local plugins = require'packer'.startup(function()
  -- Packer itself
  use 'wbthomason/packer.nvim'

  -- Lsp & TreeSitter
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-compe'
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'jose-elias-alvarez/null-ls.nvim'

  -- Plugins
  use 'folke/zen-mode.nvim'
  use 'folke/trouble.nvim'
  use 'folke/todo-comments.nvim'
  use { 'kyazdani42/nvim-tree.lua', requires = 'kyazdani42/nvim-web-devicons' }
  use { 'lewis6991/gitsigns.nvim', requires = 'nvim-lua/plenary.nvim' }
  use { 'nvim-telescope/telescope.nvim', requires = {
    'nvim-lua/popup.nvim',
    'nvim-lua/plenary.nvim'
  }}
  use 'hoob3rt/lualine.nvim'
  use 'akinsho/nvim-bufferline.lua'
  use 'numToStr/Comment.nvim'
  use 'JoosepAlviste/nvim-ts-context-commentstring'
  use 'jiangmiao/auto-pairs'
  use 'rmagatti/goto-preview'
  use 'kdheepak/lazygit.nvim'
  use 'tversteeg/registers.nvim'
  use 'glepnir/dashboard-nvim'
  use 'onsails/lspkind-nvim'
  use 'norcalli/nvim-colorizer.lua'
  use 'ray-x/lsp_signature.nvim'
  use 'windwp/nvim-ts-autotag'
  use 'github/copilot.vim'
  use 'lewis6991/impatient.nvim'
  use 'akinsho/toggleterm.nvim'
  use 'stevearc/dressing.nvim'

  -- Themes
  use 'folke/tokyonight.nvim'
  use 'catppuccin/nvim'
end)

require'impatient'

require'nvim-tree'.setup {}
require'gitsigns'.setup {}
require'zen-mode'.setup {}
require'todo-comments'.setup {}
require'lspkind'.init {}
require'trouble'.setup {}
require'goto-preview'.setup {}
require'colorizer'.setup {}
require'toggleterm'.setup {}

return plugins
