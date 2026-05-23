return {
  -- Themes
  {
    'catppuccin/nvim',
    priority = 1000,
    config = function()
      require('catppuccin').setup({
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        transparent_background = true,
        custom_highlights = function(colors)
          local utils = require('catppuccin.utils.colors')
          return {
            CursorLine = { bg = utils.blend(colors.overlay0, colors.base, 0.2) },
          }
        end,
        float = {
          transparent = true,
        },
        integrations = {
          cmp = true,
          gitsigns = {
            enabled = true,
            transparent = true,
          },
          nvimtree = true,
          treesitter = true,
          fidget = true,
          mason = true,
          snacks = {
            enabled = true,
          },
          grug_far = true,
        },
      })

      local function set_catppuccin_highlights()
        local highlights = {
          MsgSeparator = { link = 'WinSeparator' },
          GitSignsAddPreview = { bg = '#313943' },
          GitSignsDeletePreview = { bg = '#383143' },
          GitSignsDeleteVirtLn = { bg = '#383143' },
          GitSignsVirtLnum = { fg = '#ed8796', bg = '#383143', bold = true },
          GitSignsAddInline = { bg = '#455450', bold = true },
          GitSignsDeleteInline = { bg = '#563f51', bold = true },
          GitSignsChangeInline = { bg = '#455450', bold = true },
          GitSignsAddLnInline = { link = 'GitSignsAddInline' },
          GitSignsDeleteLnInline = { link = 'GitSignsDeleteInline' },
          GitSignsChangeLnInline = { link = 'GitSignsChangeInline' },
          GitSignsDeleteVirtLnInLine = { link = 'GitSignsDeleteInline' },
        }

        for group, opts in pairs(highlights) do
          vim.api.nvim_set_hl(0, group, opts)
        end
      end

      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('set-catppuccin-highlights', { clear = true }),
        pattern = 'catppuccin*',
        callback = set_catppuccin_highlights,
      })
      vim.cmd.colorscheme('catppuccin-nvim')
    end,
  },
  -- Others
  {
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    config = function()
      require('nvim-ts-autotag').setup()
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup()
    end,
  },
  {
    'j-hui/fidget.nvim',
    tag = 'v1.6.1',
    event = 'LspAttach',
    config = function()
      require('fidget').setup({
        notification = {
          window = {
            winblend = 0,
          },
        },
      })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('gitsigns').setup({
        preview_config = {
          border = 'rounded',
        },
      })
    end,
  },
  {
    'folke/persistence.nvim',
    config = function()
      if vim.fn.argc() > 0 then
        return
      end
      require('persistence').setup()
      require('persistence').load()
    end,
  },
  {
    'MagicDuck/grug-far.nvim',
    keys = {
      { '<leader>S', '<cmd>GrugFar<cr>' },
    },
    config = function()
      require('grug-far').setup({
        debounceMs = 100,
        maxSearchMatches = 1000,
        enabledEngines = { 'ripgrep' },
        engines = {
          ripgrep = {
            defaults = {
              flags = '--smart-case --hidden --fixed-strings --glob !.git',
            },
          },
        },
        showCompactInputs = true,
        showStatusIcon = false,
        showEngineInfo = false,
        transient = true,
        folding = {
          enabled = false,
        },
        resultLocation = {
          showNumberLabel = false,
        },
      })
      vim.api.nvim_set_hl(0, 'GrugFarResultsMatch', { link = 'Search' })
    end,
  },
  {
    'https://codeberg.org/fosk/registers.nvim',
    keys = {
      { '"', mode = { 'n', 'v' } },
    },
    config = function()
      local registers = require('registers')
      local normal_registers = registers.show_window({ mode = 'motion' })
      local visual_registers = registers.show_window({ mode = 'motion' })

      -- In UI2's pager, pressing " focuses the registers floating window and closes the pager
      -- since it's not longer focused. Don't use the registers floating window in that case
      local function show_registers_unless_ui2_pager(callback)
        return function()
          if vim.bo.filetype == 'pager' then
            return '"'
          end
          return callback()
        end
      end

      ---@diagnostic disable-next-line: missing-fields
      registers.setup({
        -- + system clipboard
        -- " last yank / delete
        -- 0 last yank
        -- 1-9 last deletes
        -- a-z named registers
        show = '+"0123456789abcdefghijklmnopqrstuvwxyz',
        show_empty = false,
        show_register_types = false,
        bind_keys = {
          normal = show_registers_unless_ui2_pager(normal_registers),
          visual = show_registers_unless_ui2_pager(visual_registers),
        },
        window = {
          border = 'rounded',
          transparency = 0,
        },
      })
    end,
  },
  {
    'laytan/cloak.nvim',
    event = { 'BufReadPre .env*', 'BufNewFile .env*' },
    keys = {
      { '<leader>k', '<cmd>CloakToggle<cr>', mode = { 'n', 'v' } },
    },
    config = function()
      require('cloak').setup()
    end,
  },
  {
    'dstein64/nvim-scrollview',
    event = { 'BufReadPre', 'BufNewFile' },
    after = 'gitsigns.nvim',
    config = function()
      require('scrollview').setup({
        current_only = true,
        mode = 'simple',
        signs_on_startup = { 'diagnostics', 'folds', 'search' },
      })
      require('scrollview.contrib.gitsigns').setup()
    end,
  },
  {
    'QuiiBz/pretty-quickfix.nvim',
    -- dir = '~/dev/pretty-quickfix.nvim',
    dependencies = { 'nvim-web-devicons' },
    ft = { 'qf' },
    opts = {},
  },
  {
    'QuiiBz/date-formatter.nvim',
    -- dir = '~/dev/date-formatter.nvim',
    opts = { auto = true },
  },
}
