-- disable netrw at the very start of your init.lua (nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true
-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
-- Show extra column https://www.reddit.com/r/neovim/comments/neaeej/only_just_discovered_set_signcolumnnumber_i_like/
vim.opt.signcolumn = 'yes'
-- Hide status bar
-- vim.o.ls = 0
-- Hide command height
vim.o.ch = 0
-- Spelling in comments
-- vim.opt.spell = true
-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
-- Show cursor line
vim.opt.cursorline = true
-- Overscroll by 10 lines
vim.opt.scrolloff = 10

-- Diagnostic icons
vim.fn.sign_define('DiagnosticSignError',
  { text = ' ', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn',
  { text = ' ', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo',
  { text = ' ', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint',
  { text = '', texthl = 'DiagnosticSignHint' })

-- Keybinds
-- Git
vim.cmd('nnoremap <silent> <leader>gp :Gitsigns preview_hunk<CR>')
vim.cmd('nnoremap <silent> <leader>gr :Gitsigns reset_hunk<CR>')
vim.cmd('nnoremap <silent> <leader>gg :LazyGit<CR>')
-- Resize
vim.cmd('nnoremap <silent> <C-Up> :resize -2<CR>')
vim.cmd('nnoremap <silent> <C-Down> :resize +2<CR>')
vim.cmd('nnoremap <silent> <C-Left> :vertical resize -2<CR>')
vim.cmd('nnoremap <silent> <C-Right> :vertical resize +2<CR>')
-- Bufferline
vim.cmd('nnoremap <silent> <A-Left> :BufferLineCyclePrev<CR>')
vim.cmd('nnoremap <silent> <A-Right> :BufferLineCycleNext<CR>')
vim.cmd('nnoremap <silent> <leader>< :BufferLineMovePrev<CR>')
vim.cmd('nnoremap <silent> <leader>> :BufferLineMoveNext<CR>')
vim.cmd('nnoremap <silent> <leader>c :bp\\|bd #<CR>')
vim.cmd('nnoremap <silent> <C-s> :BufferLinePick<CR>')

vim.cmd('nnoremap <silent> <leader>d :lua vim.diagnostic.open_float()<CR>')
