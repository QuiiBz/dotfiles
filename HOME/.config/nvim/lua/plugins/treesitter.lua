return {
  {
    'nvim-treesitter/nvim-treesitter',
    version = false,
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    cmd = { 'TSUpdateSync' },
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    init = function()
      local configs = require('nvim-treesitter.configs')

      configs.setup({
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
      })

      -- Commenting in JSX/TSX
      require('ts_context_commentstring').setup({
        enable_autocmd = false,
      })
    end
  }
}
