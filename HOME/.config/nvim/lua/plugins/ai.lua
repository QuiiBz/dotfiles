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
            accept = false,
          },
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
          settings = {
            telemetry = {
              telemetryLevel = 'off',
            },
          },
        },
      })
    end,
  },
  {
    'folke/sidekick.nvim',
    opts = {
      cli = {
        mux = {
          enabled = true,
        },
      },
    },
    keys = {
      {
        '<tab>',
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require('sidekick').nes_jump_or_apply() then
            return ':BufferLineCycleNext<CR>' -- fall back to next tab
          end
        end,
        expr = true,
      },
      {
        '<leader>aa',
        function()
          require('sidekick.cli').toggle()
        end,
        mode = { 'n' },
      },
      {
        '<leader>aa',
        function()
          require('sidekick.cli').send({ selection = true })
        end,
        mode = { 'v' },
      },
    },
  },
}
