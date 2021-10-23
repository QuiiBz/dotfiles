local plugins = require'packer'.startup(function()
  -- Packer itself
  use 'wbthomason/packer.nvim'

  -- Lsp & TreeSitter
  use 'neovim/nvim-lspconfig'
  -- use 'hrsh7th/nvim-compe'
  use { 'hrsh7th/nvim-cmp', requires = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lua',
  }}
  use { 'L3MON4D3/LuaSnip', requires = 'saadparwaiz1/cmp_luasnip' }
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'kabouzeid/nvim-lspinstall'
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
  use 'tpope/vim-commentary'
  use 'jiangmiao/auto-pairs'
  use 'rmagatti/goto-preview'
  use 'kdheepak/lazygit.nvim'
  use 'tversteeg/registers.nvim'
  use 'glepnir/dashboard-nvim'
  use 'onsails/lspkind-nvim'
  use 'norcalli/nvim-colorizer.lua'
  use 'projekt0n/circles.nvim'
  use 'ray-x/lsp_signature.nvim'
  use 'windwp/nvim-ts-autotag'

  -- Themes
  use 'folke/tokyonight.nvim'
  use 'projekt0n/github-nvim-theme'
end)

require'lspinstall'.setup {}
require'nvim-tree'.setup {}
require'gitsigns'.setup {}
require'zen-mode'.setup {}
require'todo-comments'.setup {}
require'trouble'.setup {}
require'goto-preview'.setup {}
require'colorizer'.setup {}
-- require'circles'.setup {
--   lsp = true
-- }

return plugins
