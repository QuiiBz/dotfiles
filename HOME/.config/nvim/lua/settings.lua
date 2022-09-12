vim.g.tokyonight_style = "night"
vim.g.catppuccin_flavour = "macchiato" -- latte, frappe, macchiato, mocha

-- vim.cmd("colorscheme tokyonight")
-- vim.cmd("colorscheme catppuccin")
require("catppuccin").setup()
vim.cmd("colorscheme catppuccin")
-- require'github-theme'.setup {
--   theme_style = 'light',
--   sidebars = { 'terminal' }
-- }

vim.opt.termguicolors = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.signcolumn = "yes"
vim.cmd("set noswapfile")
vim.opt.completeopt = "menuone,noselect"
vim.opt.laststatus = 2
vim.opt.bs = { 2 }
vim.opt.updatetime = 300
vim.cmd("set formatoptions-=cro")

