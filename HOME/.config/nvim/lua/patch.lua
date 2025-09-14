local patches = {
  ['satellite.nvim'] = 'satellite-gitsigns-fix.patch',
}

-- Reset repos to clean state before update
vim.api.nvim_create_autocmd('User', {
  pattern = { 'LazyInstallPre', 'LazyUpdatePre' },
  callback = function()
    for repo, _ in pairs(patches) do
      local cmd = string.format('cd ~/.local/share/nvim/lazy/%s && git reset --hard', repo)
      os.execute(cmd)
    end
  end,
})

-- Apply patches after install or update
vim.api.nvim_create_autocmd('User', {
  pattern = { 'LazyInstall', 'LazyUpdate' },
  callback = function()
    for repo, patch in pairs(patches) do
      local cmd = string.format(
        'cd ~/.local/share/nvim/lazy/%s && git apply ~/.config/nvim/patches/%s',
        repo,
        patch
      )
      os.execute(cmd)
    end
  end,
})
