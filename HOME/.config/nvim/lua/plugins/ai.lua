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
          settings = {
            telemetry = {
              telemetryLevel = "off",
            },
          },
        },
      })
    end
  }
}
