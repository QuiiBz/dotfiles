vim.opt.termguicolors = true
-- Line numbers
vim.opt.number = true
-- Minimum 1 char for line numbers, instead of 4 default
vim.opt.numberwidth = 1
-- Show extra column but max 1 https://www.reddit.com/r/neovim/comments/neaeej/only_just_discovered_set_signcolumnnumber_i_like/
vim.opt.signcolumn = 'yes:1'
-- Hide status bar
-- vim.o.ls = 0
-- Hide command height
vim.o.ch = 0
-- Set rounded borders
vim.o.winborder = 'rounded'
-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
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
-- Enable background cursor line
vim.opt.cursorline = true
-- Only save useful info in sessions
vim.o.sessionoptions = 'buffers,curdir,folds,globals,winpos,winsize'
-- Scroll line by line
vim.o.mousescroll = 'ver:1'
-- :term should use zsh
vim.o.shell = '/bin/zsh -l'

-- Keybinds
-- Git
vim.cmd('nnoremap <silent> <leader>gp :Gitsigns preview_hunk<CR>')
vim.cmd('nnoremap <silent> <leader>gr :Gitsigns reset_hunk<CR>')
vim.cmd('nnoremap <silent> <leader>gl :Gitsigns blame_line<CR>')
vim.cmd('nnoremap <silent> <leader>gb :Gitsigns blame<CR>')
vim.cmd('nnoremap <silent> ]g :Gitsigns next_hunk<CR>')
vim.cmd('nnoremap <silent> [g :Gitsigns prev_hunk<CR>')
vim.cmd('nnoremap <silent> <leader>gg :lua Snacks.lazygit()<CR>')
-- Resize
vim.cmd('nnoremap <silent> <C-Up> :resize -2<CR>')
vim.cmd('nnoremap <silent> <C-Down> :resize +2<CR>')
vim.cmd('nnoremap <silent> <C-Left> :vertical resize -2<CR>')
vim.cmd('nnoremap <silent> <C-Right> :vertical resize +2<CR>')
-- Bufferline
vim.cmd('nnoremap <silent> <Tab> :BufferLineCycleNext<CR>')
vim.cmd('nnoremap <silent> <S-Tab> :BufferLineCyclePrev<CR>')
vim.cmd('nnoremap <silent> <leader>< :BufferLineMovePrev<CR>')
vim.cmd('nnoremap <silent> <leader>> :BufferLineMoveNext<CR>')
-- Close buffer and move to the next one, but if it's the last one, move to the previous one
vim.keymap.set('n', '<leader>c', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local move_prev = false
  local ok, bufferline = pcall(require, 'bufferline')
  if ok and type(bufferline.get_elements) == 'function' then
    local elements = bufferline.get_elements().elements or {}
    local last = elements[#elements]
    move_prev = last and last.id == bufnr or false
  end

  if move_prev then
    vim.cmd('BufferLineCyclePrev')
  else
    vim.cmd('BufferLineCycleNext')
  end
  vim.cmd('bdelete ' .. bufnr)
end, { silent = true })
-- Close all buffers except the current one
vim.cmd('nnoremap <silent> <leader>C :BufferLineCloseOthers<CR>')
-- Open diagnostics in floating window
vim.cmd('nnoremap <silent> <leader>d :lua vim.diagnostic.open_float()<CR>')
-- Copilot super tab
vim.keymap.set('i', '<Tab>', function()
  local copilot = require('copilot.suggestion')
  if copilot.is_visible() then
    copilot.accept()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
  end
end)
-- Disable q: because I accidentally hit it
vim.cmd('nnoremap q: <Nop>')
-- Escale terminal mode with Esc
vim.cmd('tnoremap <C-q> <C-\\><C-n>')

-- Keep the cursor where the comment operation started
local comment_start_cursor = nil
local function clamp_col(line, col)
  return math.min(col, #vim.fn.getline(line))
end
_G.__comment_keep_cursor_position = function()
  local line_start = vim.fn.line("'[")
  local line_end = vim.fn.line("']")
  local ref_position = comment_start_cursor or { line_start, 0 }
  local cursor_line = math.min(math.max(ref_position[1], line_start), line_end)
  require('vim._comment').toggle_lines(line_start, line_end, ref_position)
  vim.api.nvim_win_set_cursor(0, { cursor_line, clamp_col(cursor_line, ref_position[2]) })
end
local function comment_operator()
  comment_start_cursor = vim.api.nvim_win_get_cursor(0)
  vim.o.operatorfunc = 'v:lua.__comment_keep_cursor_position'
  return 'g@'
end
vim.keymap.set({ 'n', 'x' }, 'gc', comment_operator, { expr = true, desc = 'Toggle comment' })
vim.keymap.set('n', 'gcc', function()
  return comment_operator() .. '_'
end, { expr = true, desc = 'Toggle comment line' })

-- Keep the cursor where the visual selection ended after yanking
vim.keymap.set('x', 'y', 'ygv<Esc>', { noremap = true, silent = true })

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = 'Visual' })
  end,
})

-- When opening a file from lazygit within neovim, it sometimes breaks the line numbers
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  group = vim.api.nvim_create_augroup('force-line-numbers', { clear = true }),
  callback = function(args)
    if vim.bo[args.buf].buftype == '' then
      vim.go.number = true
      vim.wo.number = true
    end
  end,
})

-- Disable automatic comments on new lines
vim.cmd('autocmd BufEnter * set formatoptions-=cro')
vim.cmd('autocmd BufEnter * setlocal formatoptions-=cro')

function ToggleQuickfix()
  local windows = vim.fn.getwininfo()
  for _, win in ipairs(windows) do
    if win.quickfix == 1 then
      vim.cmd('cclose')
      return
    end
  end
  vim.cmd('copen')
end

-- Toggle quickfix list
vim.keymap.set('n', '<leader>q', ToggleQuickfix, { noremap = true, silent = true })

-- Testing out ui2
require('vim._core.ui2').enable({
  msg = {
    pager = {
      height = 0.5,
    },
  },
})

-- Enable builtin :Undotree
vim.cmd('packadd nvim.undotree')
