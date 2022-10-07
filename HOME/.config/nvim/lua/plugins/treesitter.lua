require('nvim-treesitter.configs').setup({
  auto_install = true,
  highlight = {
    enable = true,
  },
  autotag = {
    enable = true,
  },
  -- Indent based on treesitter for =
  indent = {
    enable = true,
  },
  -- Commenting in JSX/TSX
  context_commentstring = {
    enable = true,
    enable_autocmd = false,
  },
})

