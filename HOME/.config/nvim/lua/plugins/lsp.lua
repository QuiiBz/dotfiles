local servers = {
  -- Languages
  'lua_ls',
  'rust_analyzer',
  'tsserver',
  'cssls',
  'html',
  'jsonls',
  'gopls',
  'phpactor',
  'volar',
  -- Web
  'prismals',
  'astro',
  'tailwindcss',
  'eslint',
  -- Other
  'dockerls',
  'terraformls',
}

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'williamboman/mason-lspconfig.nvim' },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = servers,
      })

      local lsp = require('lspconfig')
      local augroup = vim.api.nvim_create_augroup('LspFormatting', { clear = true })

      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        if client.name == 'eslint' then
          client.server_capabilities.documentFormattingProvider = true
        end

        if client.supports_method('textDocument/formatting') then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end,
          })
        end

        -- Mappings
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
        -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
        -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
        -- vim.keymap.set('n', '<space>wl', function()
        --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        -- end, bufopts)
        vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set('n', '<space>r', vim.lsp.buf.rename, bufopts)
        -- Handled by :CodeActionMenu
        -- vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, bufopts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
        vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
      end

      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Attach LSP servers
      for _, server in pairs(servers) do
        local config = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        lsp[server].setup(config)
      end

      -- Rounded borders for hover
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = 'rounded'
      })

      -- Fix floating windows color
      vim.api.nvim_set_hl(0, 'NormalFloat', {
        link = 'Normal',
      })

      vim.api.nvim_set_hl(0, 'FloatBorder', {
        bg = 'none',
      })
    end
  },
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    build = ':MasonUpdate',
    config = function()
      require('mason').setup({
        ui = {
          border = 'rounded',
          width = 0.8,
          height = 0.8,
        }
      })
    end
  },
}
