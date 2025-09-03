local servers = {
  -- Languages
  'lua_ls',
  'rust_analyzer',
  'vtsls',
  'cssls',
  'html',
  'jsonls',
  'gopls',
  'clangd',
  'basedpyright',
  -- 'vue_ls',
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
    dependencies = {
      'saghen/blink.cmp',
      'williamboman/mason-lspconfig.nvim',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = servers,
        automatic_enable = false,
      })

      local lsp = require('lspconfig')
      local augroup = vim.api.nvim_create_augroup('LspFormatting', { clear = true })

      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

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

      local capabilities = require('blink.cmp').get_lsp_capabilities()
      capabilities.general = { positionEncodings = { 'utf-16' } } -- Make sure we always use UTF-16 for all LSPs

      -- Attach LSP servers
      for _, server in pairs(servers) do
        local config = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        -- Only run the TailwindCSS LSP when a config is present
        if server == 'tailwindcss' then
          config.filetypes = { 'html', 'css', 'scss', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact',
            'vue', 'astro' }
        end

        if server == 'lua_ls' then
          config.settings = {
            Lua = {
              diagnostics = {
                globals = { 'vim' }, -- Recognize 'vim' as a global variable
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file('', true), -- Include Neovim runtime files
              },
              telemetry = {
                enable = false, -- Disable telemetry
              },
            },
          }
        end

        -- Increase max memory for tsserver
        if server == 'vtsls' then
          config.settings = {
            typescript = {
              tsserver = {
                maxTsServerMemory = 8192, -- 8GB
              },
            },
          }
        end

        lsp[server].setup(config)
      end

      -- Disable LSP logs from ~/.local/state/nvim/lsp.log
      vim.lsp.log.set_level(vim.log.levels.OFF)

      vim.diagnostic.config({
        -- Show inline diagnostics
        virtual_text = true,
        -- Rounded borders for diagnostics float
        float = { border = 'rounded' },
        -- Diagnostic icons
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "",
          }
        }
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
