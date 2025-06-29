-- disable netrw at the very start of your init.lua (nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true
-- Line numbers
vim.opt.number = true
-- Show extra column https://www.reddit.com/r/neovim/comments/neaeej/only_just_discovered_set_signcolumnnumber_i_like/
vim.opt.signcolumn = 'yes'
-- Hide status bar
-- vim.o.ls = 0
-- Hide command height
vim.o.ch = 0
-- Spelling in comments
-- vim.opt.spell = true
-- Set rounded borders
vim.o.winborder = 'rounded'
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
-- Ignore case in search
vim.opt.ignorecase = true
-- Do not ignore case in search if there is a capital letter
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.swapfile = false
-- Just makes sense when spliting windows
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Diagnostic icons
vim.fn.sign_define('DiagnosticSignError',
  { text = ' ', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn',
  { text = ' ', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo',
  { text = ' ', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint',
  { text = '', texthl = 'DiagnosticSignHint' })

-- Keybinds
-- Git
vim.cmd('nnoremap <silent> <leader>gp :Gitsigns preview_hunk<CR>')
vim.cmd('nnoremap <silent> <leader>gr :Gitsigns reset_hunk<CR>')
vim.cmd('nnoremap <silent> <leader>gg :lua Snacks.lazygit()<CR>')
-- Resize
vim.cmd('nnoremap <silent> <C-Up> :resize -2<CR>')
vim.cmd('nnoremap <silent> <C-Down> :resize +2<CR>')
vim.cmd('nnoremap <silent> <C-Left> :vertical resize -2<CR>')
vim.cmd('nnoremap <silent> <C-Right> :vertical resize +2<CR>')
-- Bufferline
vim.cmd('nnoremap <silent> <A-Left> :BufferLineCyclePrev<CR>')
vim.cmd('nnoremap <silent> <A-Right> :BufferLineCycleNext<CR>')
vim.cmd('nnoremap <silent> <S-Tab> :BufferLineCyclePrev<CR>')
vim.cmd('nnoremap <silent> <Tab> :BufferLineCycleNext<CR>')
vim.cmd('nnoremap <silent> <Esc>b :BufferLineCyclePrev<CR>')
vim.cmd('nnoremap <silent> <Esc>f :BufferLineCycleNext<CR>')
vim.cmd('nnoremap <silent> <leader>< :BufferLineMovePrev<CR>')
vim.cmd('nnoremap <silent> <leader>> :BufferLineMoveNext<CR>')
vim.cmd('nnoremap <silent> <leader>c :bp<bar>sp<bar>bn<bar>bd<CR>')
vim.cmd('nnoremap <silent> <C-s> :BufferLinePick<CR>')

-- Open diagnostics in floating window
vim.cmd('nnoremap <silent> <leader>d :lua vim.diagnostic.open_float()<CR>')

-- Go to next/previous item in quickfix list
vim.cmd('nnoremap <silent> <leader>n :cnext<CR>')
vim.cmd('nnoremap <silent> <leader>p :cprev<CR>')

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = 'Visual' })
  end
})

-- LSP-integrated file renaming
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesActionRename',
  callback = function(event)
    Snacks.rename.on_rename_file(event.data.from, event.data.to)
  end,
})

-- Disable automatic comments on new lines
vim.cmd('autocmd BufEnter * set formatoptions-=cro')
vim.cmd('autocmd BufEnter * setlocal formatoptions-=cro')
