-- Lazy requires mapleader to be set before it is loaded
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', {
  ui = {
    border = 'rounded',
  },
  change_detection = {
    enabled = false,
  },
})

-- Fix the double border issue while we wait for lazy.nvim to fix it
-- https://github.com/folke/lazy.nvim/issues/1951
vim.api.nvim_create_autocmd('FileType', {
  desc = 'User: fix backdrop for lazy window',
  pattern = 'lazy_backdrop',
  group = vim.api.nvim_create_augroup('lazynvim-fix', { clear = true }),
  callback = function(ctx)
    local win = vim.fn.win_findbuf(ctx.buf)[1]
    vim.api.nvim_win_set_config(win, { border = 'none' })
  end,
})

require('settings')
