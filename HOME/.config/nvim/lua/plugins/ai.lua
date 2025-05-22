return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = '<tab>',
          }
        },
        filetypes = {
          yaml = true,
          markdown = true,
        },
        server = {
          type = 'binary',
        },
        server_opts_overrides = {
          offset_encoding = 'utf-16',
        },
      })
    end
  },
  {
    'yetone/avante.nvim',
    cmd = 'AvanteChat',
    keys = {
      { '<leader>aa', '<cmd>AvanteChat<cr>' }
    },
    version = 'v0.0.23',
    opts = {
      provider = 'copilot',
      copilot = {
        model = 'gpt-4.1',
        max_tokens = 120000, -- max tokens for GPT-4.1 is 128k, so add some buffer
      },
      auto_suggestions_provider = nil,
      behaviour = {
        auto_suggestions = false,
      },
      hints = {
        enabled = false,
      },
    },
    build = 'make',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'zbirenbaum/copilot.lua',
      'MeanderingProgrammer/render-markdown.nvim',
    },
  }
}
