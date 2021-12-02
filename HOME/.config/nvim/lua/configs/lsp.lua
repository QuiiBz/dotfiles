local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', '<C-g>', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

  client.resolved_capabilities.document_formatting = false
  client.resolved_capabilities.document_range_formatting = false

  if client.name == "eslint" then
    client.resolved_capabilities.document_formatting = true
  end

  -- eslint on save
  if (client.name == "tsserver") then
    vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
  end

  require "lsp_signature".on_attach({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    floating_window = false,
    handler_opts = {
      border = "single"
    }
  })
end

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
  'html',
  'eslint'
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

  if server == 'eslint' then
    config.settings = {
      packageManager = 'yarn',
    }
  end

  require'lspconfig'[server].setup(config)
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true;
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

vim.lsp.handlers["textDocument/formatting"] = function(err, _, result, _, bufnr)
  if err ~= nil or result == nil then
    return
  end

  if not vim.api.nvim_buf_get_option(bufnr, "modified") then
    local view = vim.fn.winsaveview()
    vim.lsp.util.apply_text_edits(result, bufnr)
    vim.fn.winrestview(view)

    if bufnr == vim.api.nvim_get_current_buf() then
      vim.api.nvim_command("noautocmd :update")
    end
  end
end

local signs = { Error = " ", Warn = " ", Hint = " ", Information = " " }

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

