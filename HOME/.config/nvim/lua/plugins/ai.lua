return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'VeryLazy',
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
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { 'markdown', 'Avante' },
        },
        ft = { 'markdown', 'Avante' },
      },
    },
  }
}
