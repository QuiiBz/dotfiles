return {
  {
    'nvim-treesitter/nvim-treesitter',
    version = false,
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    cmd = { 'TSUpdateSync' },
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
    end
  }
}
