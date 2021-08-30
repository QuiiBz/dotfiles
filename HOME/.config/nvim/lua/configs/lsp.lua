local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', '<C-g>', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

  if client.name == "java_language_server" then
    client.resolved_capabilities.document_formatting = false
  end

  client.resolved_capabilities.document_formatting = false
  client.resolved_capabilities.document_range_formatting = false

  -- define an alias
  -- vim.cmd("command -buffer Formatting lua vim.lsp.buf.formatting()")
  -- vim.cmd("command -buffer FormattingSync lua vim.lsp.buf.formatting_sync()")

  -- format on save
  vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")

  local ts_utils = require("nvim-lsp-ts-utils")

  -- defaults
  ts_utils.setup {
      debug = false,
      disable_commands = false,
      enable_import_on_completion = false,

      -- import all
      import_all_timeout = 5000, -- ms
      import_all_priorities = {
          buffers = 4, -- loaded buffer names
          buffer_content = 3, -- loaded buffer content
          local_files = 2, -- git files or files with relative path markers
          same_file = 1, -- add to existing import statement
      },
      import_all_scan_buffers = 100,
      import_all_select_source = false,

      -- eslint
      eslint_enable_code_actions = true,
      eslint_enable_disable_comments = true,
      eslint_bin = "eslint_d",
      eslint_config_fallback = nil,
      eslint_enable_diagnostics = true,
      eslint_show_rule_id = false,

      -- formatting
      enable_formatting = true,
      formatter = "eslint_d",
      formatter_config_fallback = nil,

      -- update imports on file move
      update_imports_on_move = true,
      require_confirmation_on_move = false,
      watch_dir = nil,

      -- filter diagnostics
      filter_out_diagnostics_by_severity = {},
      filter_out_diagnostics_by_code = {},
  }

  -- required to fix code action ranges and filter diagnostics
  ts_utils.setup_client(client)


  require "lsp_signature".on_attach({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    floating_window = false,
    handler_opts = {
      border = "single"
    }
  })
end

local function setup_lsp()
  require'lspinstall'.setup()
  require("null-ls").config {}
  require("lspconfig")["null-ls"].setup {}

  local servers = {
    'vimls',
    'sumneko_lua',
    'tsserver',
    'rust_analyzer',
    'java_language_server',
    'cssls',
    'jsonls',
    'html'
  }

  local config_path = vim.fn.stdpath('config')

  for _, server in pairs(servers) do
    local config = { on_attach = on_attach }

    if server == 'java_language_server' then
      config.cmd = { config_path.."/java-language-server/dist/lang_server_mac.sh" }
      config.filetypes = { 'java' }
      config.settings = {  }
    end

    if server == 'sumneko_lua' then
      local system_name
      if vim.fn.has("mac") == 1 then
        system_name = "macOS"
      elseif vim.fn.has("unix") == 1 then
        system_name = "Linux"
      elseif vim.fn.has('win32') == 1 then
        system_name = "Windows"
      else
        print("Unsupported system for sumneko")
      end

      -- set the path to the sumneko installation; if you previously installed via the now deprecated :LspInstall, use
      local sumneko_root_path = config_path..'/lua-language-server'
      local sumneko_binary = sumneko_root_path.."/bin/"..system_name.."/lua-language-server"

      local runtime_path = vim.split(package.path, ';')
      table.insert(runtime_path, "lua/?.lua")
      table.insert(runtime_path, "lua/?/init.lua")

      config.cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" };
      config.settings = {
        Lua = {
          runtime = {
            -- LuaJIT in the case of Neovim
            version = 'LuaJIT',
            path = vim.split(package.path, ';'),
          },
          diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = {'vim'},
          },
          workspace = {
            -- Make the server aware of Neovim runtime files
            library = {
              [vim.fn.expand('$VIMRUNTIME/lua')] = true,
              [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
            },
          },
        }
      }
    end

    if server == 'cssls' or server == 'jsonls' or server == 'html' then
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      config.capabilities = capabilities
    end

    require'lspconfig'[server].setup(config)
  end
end

setup_lsp()

-- Automatically reload after `:LspInstall <server>` so we don't have to restart neovim
require'lspinstall'.post_install_hook = function ()
  setup_lsp() -- reload installed servers
  vim.cmd("bufdo e") -- this triggers the FileType autocmd that starts the server
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = false,
    virtual_text = {
      spacing = 4,
      prefix = ''
    }
  }
)

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "single"
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "single"
})

local signs = { Error = " ", Warning = " ", Hint = " ", Information = " " }

for type, icon in pairs(signs) do
  local hl = "LspDiagnosticsSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

