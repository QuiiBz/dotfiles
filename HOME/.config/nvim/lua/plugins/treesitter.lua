return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local treesitter = require('nvim-treesitter')
          local lang = vim.treesitter.language.get_lang(args.match)
          -- If this lang is available
          if vim.list_contains(treesitter.get_available(), lang) then
            -- Install it if not already installed
            if not vim.list_contains(treesitter.get_installed(), lang) then
              treesitter.install(lang):wait()
            end
            -- Start treesitter highlighting
            vim.treesitter.start(args.buf)
            -- Enable treesitter-based indentation
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
        desc = 'Enable nvim-treesitter and install parser if not installed',
      })
    end,
  },
}
