vim.g.tokyonight_style = "night"
-- vim.cmd("colorscheme tokyonight")
-- vim.cmd("colorscheme catppuccin")

require'github-theme'.setup {
  theme_style = 'light',
  sidebars = { 'terminal' }
}

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

vim.g.nvim_tree_git_hl = 1
vim.g.nvim_tree_indent_markers = 1
vim.g.nvim_tree_show_icons = {
  git = 1,
  folders = 1,
  files = 1,
  folder_arrows = 0
}

-- Dashboard
vim.g.dashboard_default_executive = "telescope"
vim.g.dashboard_custom_header = {
  "                                 ",
  "                                 ",
  " ▐ ▄ ▄▄▄ .       ▌ ▐·▪  • ▌ ▄ ·. ",
  "•█▌▐█▀▄.▀·▪     ▪█·█▌██ ·██ ▐███▪",
  "▐█▐▐▌▐▀▀▪▄ ▄█▀▄ ▐█▐█•▐█·▐█ ▌▐▌▐█·",
  "██▐█▌▐█▄▄▌▐█▌.▐▌ ███ ▐█▌██ ██▌▐█▌",
  "▀▀ █▪ ▀▀▀  ▀█▄▀▪. ▀  ▀▀▀▀▀  █▪▀▀▀",
  "                                 ",
  "                                 "
}

vim.g.dashboard_custom_footer = { }
vim.g.dashboard_custom_section = {
  a = {
    description = { "  Recently Used Files" },
    command = "Telescope oldfiles"
  },
  b = {
    description = { "  Load Last Session  " },
    command = "SessionLoad"
  },
  c = {
    description = { "  Find File          " },
    command = "Telescope find_files"
  },
  d = {
    description = { "  Find Word          "},
    command = "Telescope live_grep"
  },
 }

