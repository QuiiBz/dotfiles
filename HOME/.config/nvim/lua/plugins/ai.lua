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
    config = function()
      require('sidekick').setup({
        cli = {
          mux = {
            enabled = true,
          },
          win = {
            keys = {
              -- send prompt without a \n suffix
              prompt = {
                '<c-p>',
                function(t)
                  vim.cmd.stopinsert()
                  vim.schedule(function()
                    require('sidekick.cli').prompt(function(prompt)
                      vim.schedule(function()
                        vim.cmd.startinsert()
                      end)
                      if prompt and prompt ~= '' then
                        t:send(prompt)
                      end
                    end)
                  end)
                end,
                mode = 't',
              },
            },
          },
          tools = {
            codex = {
              -- allow live updates when going back to normal mode with ctrl+q
              native_scroll = true,
            },
          },
        },
      })

      -- sidekick deep-merges prompts with defaults, so replacing with custom prompts
      require('sidekick.config').cli.prompts = {
        file = '{file} ',
        git = 'check the current git changes, ',
        line = '{line} ',
      }
    end,
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
