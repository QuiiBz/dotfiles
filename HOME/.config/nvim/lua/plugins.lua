local plugins = require'packer'.startup(function()
  -- Packer itself
  use 'wbthomason/packer.nvim'

  -- Lsp & TreeSitter
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-compe'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/nvim-cmp'
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- Plugins
  use 'folke/zen-mode.nvim'
  use 'folke/trouble.nvim'
  use 'folke/todo-comments.nvim'
  use { 'kyazdani42/nvim-tree.lua', requires = 'kyazdani42/nvim-web-devicons' }
  use { 'lewis6991/gitsigns.nvim', requires = 'nvim-lua/plenary.nvim' }
  use { 'nvim-telescope/telescope.nvim', requires = {
    'nvim-lua/popup.nvim',
    'nvim-lua/plenary.nvim',
    {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
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
  use 'akinsho/toggleterm.nvim'
  use 'stevearc/dressing.nvim'
  use 'famiu/nvim-reload'

  -- Performances
  use 'lewis6991/impatient.nvim'
  use 'nathom/filetype.nvim'

  -- Not always needed
  -- use 'github/copilot.vim'
  -- use 'tweekmonster/startuptime.vim'

  -- Themes
  use 'folke/tokyonight.nvim'
  use 'catppuccin/nvim'
  use 'ellisonleao/gruvbox.nvim'
  use 'projekt0n/github-nvim-theme'
end)

require'impatient'

require'nvim-tree'.setup {}
require'gitsigns'.setup {}
require'zen-mode'.setup {}
require'todo-comments'.setup {}
require'trouble'.setup {}
require'goto-preview'.setup {}
require'colorizer'.setup {
  '*';
}
require'toggleterm'.setup {
  shading_factor = 0.08,
}
require'filetype'.setup {}

return plugins
