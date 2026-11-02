return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    priority = 900,
    build = ':TSUpdate',
    config = function()
      -- Use markdown parser for mdx filetypes
      vim.treesitter.language.register('markdown', 'mdx')

      local pending_buffers = {}
      local function start_highlighting(buffer, language)
        if
          not vim.api.nvim_buf_is_loaded(buffer)
          or vim.treesitter.language.get_lang(vim.bo[buffer].filetype) ~= language
        then
          return false
        end

        -- Start treesitter highlighting
        if not pcall(vim.treesitter.start, buffer, language) then
          return false
        end

        -- Enable treesitter-based indentation
        vim.bo[buffer].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        return true
      end

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local language = vim.treesitter.language.get_lang(args.match)
          if not language or start_highlighting(args.buf, language) then
            return
          end

          if pending_buffers[language] then
            pending_buffers[language][args.buf] = true
            return
          end

          local treesitter = require('nvim-treesitter')
          -- If this lang is available
          if not vim.list_contains(treesitter.get_available(), language) then
            return
          end

          pending_buffers[language] = { [args.buf] = true }
          -- Install it if not already installed
          treesitter.install(language):await(vim.schedule_wrap(function(error, installed)
            local buffers = pending_buffers[language]
            pending_buffers[language] = nil
            if error or not installed then
              return
            end

            for buffer in pairs(buffers) do
              start_highlighting(buffer, language)
            end
          end))
        end,
        desc = 'Enable nvim-treesitter and install parser if not installed',
      })
    end,
  },
}
