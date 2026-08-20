local servers = {
  -- Languages
  'tsc',
  'lua_ls',
  'stylua',
  'rust_analyzer',
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
  'biome',
  -- Other
  'dockerls',
  'terraformls',
  'buf_ls',
  'copilot',
}

return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'FileType' },
    config = function()
      local augroup = vim.api.nvim_create_augroup('LspFormatting', { clear = true })

      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

        if client.name == 'tsc' or client.name == 'lua_ls' then
          client.server_capabilities.documentFormattingProvider = false
        elseif client.name == 'biome' or client.name == 'eslint' then
          client.server_capabilities.documentFormattingProvider = true
        end

        if client:supports_method('textDocument/formatting') then
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
        vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set('n', '<space>r', vim.lsp.buf.rename, bufopts)
        vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, bufopts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
      end

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.general = { positionEncodings = { 'utf-16' } } -- Make sure we always use UTF-16 for all LSPs

      -- Attach LSP servers
      for _, server in pairs(servers) do
        local config = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        if server == 'copilot' then
          config.on_attach = vim.lsp.config[server].on_attach
          config.settings = {
            telemetry = {
              telemetryLevel = 'off',
            },
          }
        end

        if server == 'tailwindcss' then
          -- Only run the TailwindCSS LSP on these filetypes
          config.filetypes = {
            'html',
            'css',
            'scss',
            'javascript',
            'typescript',
            'javascriptreact',
            'typescriptreact',
            'vue',
            'astro',
          }
          -- Fix freeze when opening large repositories without a TailwindCSS config file
          config.settings = {
            tailwindCSS = {
              experimental = {
                configFile = '',
              },
            },
          }
        end

        if server == 'lua_ls' then
          config.settings = {
            Lua = {
              diagnostics = {
                globals = { 'vim' }, -- Recognize 'vim' as a global variable
              },
              workspace = {
                library = { vim.env.VIMRUNTIME },
              },
              telemetry = {
                enable = false, -- Disable telemetry
              },
            },
          }
        end

        -- Increase max memory for tsgo
        if server == 'tsgo' then
          config.settings = {
            typescript = {
              tsserver = {
                maxTsServerMemory = 8192, -- 8GB
              },
            },
          }
        end

        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end

      vim.lsp.inline_completion.enable()

      -- Disable LSP logs from ~/.local/state/nvim/lsp.log
      vim.lsp.log.set_level(vim.log.levels.OFF)

      vim.diagnostic.config({
        -- Show inline diagnostics
        virtual_text = {
          prefix = '●',
        },
        -- Rounded borders for diagnostics float
        float = { border = 'rounded' },
        -- Diagnostic icons
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '⨯',
            [vim.diagnostic.severity.WARN] = '⚠︎',
            [vim.diagnostic.severity.INFO] = '',
            [vim.diagnostic.severity.HINT] = '',
          },
        },
      })

      -- Enable undercurl for diagnostics
      local function copy_fg_to_sp(from, to)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = from, link = false })
        if not ok or not hl.fg then
          return
        end

        vim.api.nvim_set_hl(0, to, {
          undercurl = true,
          sp = string.format('#%06x', hl.fg),
        })
      end

      copy_fg_to_sp('DiagnosticError', 'DiagnosticUnderlineError')
      copy_fg_to_sp('DiagnosticWarn', 'DiagnosticUnderlineWarn')
      copy_fg_to_sp('DiagnosticInfo', 'DiagnosticUnderlineInfo')
      copy_fg_to_sp('DiagnosticHint', 'DiagnosticUnderlineHint')
      copy_fg_to_sp('DiagnosticOk', 'DiagnosticUnderlineOk')

      -- Fix floating windows color
      vim.api.nvim_set_hl(0, 'NormalFloat', {
        link = 'Normal',
      })

      vim.api.nvim_set_hl(0, 'FloatBorder', {
        bg = 'none',
      })
    end,
  },
  {
    'mason-org/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonUninstallAll', 'MasonUpdate', 'MasonLog' },
    build = ':MasonUpdate',
    init = function()
      vim.env.PATH = vim.fs.joinpath(vim.fn.stdpath('data'), 'mason', 'bin') .. ':' .. vim.env.PATH
    end,
    config = function()
      require('mason').setup({
        ui = {
          border = 'rounded',
          width = 0.8,
          height = 0.8,
        },
      })
    end,
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {},
  },
}
