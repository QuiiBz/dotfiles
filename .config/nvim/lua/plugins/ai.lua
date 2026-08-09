return {
  {
    'folke/sidekick.nvim',
    init = function()
      local function save_sessions()
        local Session = require('sidekick.cli.session')
        local cwd = Session.cwd()
        local sessions = {}

        for _, attached_session in pairs(Session.attached()) do
          local session = attached_session.parent or attached_session
          if session.cwd == cwd then
            sessions[#sessions + 1] = {
              backend = session.backend,
              cwd = session.cwd,
              id = session.id,
              mux_session = session.mux_session,
              started = true,
              tmux_pane_id = session.tmux_pane_id,
              tmux_pid = session.tmux_pid,
              tool = session.tool.name,
            }
          end
        end

        vim.g.SidekickSessions = vim.json.encode(sessions)
      end

      local function restore_sessions()
        local success, sessions = pcall(vim.json.decode, vim.g.SidekickSessions or '[]')
        if not success then
          return
        end

        local Session = require('sidekick.cli.session')
        local State = require('sidekick.cli.state')
        Session.setup()

        for _, session_data in ipairs(sessions) do
          local session = Session.new(session_data)
          State.attach(State.get_state(session), { show = true, focus = false })
        end
      end

      vim.api.nvim_create_autocmd('User', {
        pattern = 'PersistenceSavePre',
        group = vim.api.nvim_create_augroup('sidekick-persistence', { clear = true }),
        callback = save_sessions,
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'PersistenceLoadPost',
        group = 'sidekick-persistence',
        callback = function()
          vim.defer_fn(restore_sessions, 100)
        end,
      })
    end,
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
        '<leader>a',
        function()
          require('sidekick.cli').toggle({ name = 'codex' })
        end,
        mode = { 'n' },
      },
      {
        '<leader>a',
        function()
          require('sidekick.cli').send({ name = 'codex', selection = true })
        end,
        mode = { 'v' },
      },
      {
        '<leader>s',
        function()
          require('sidekick.cli').toggle()
        end,
        mode = { 'n' },
      },
      {
        '<leader>s',
        function()
          require('sidekick.cli').send({ selection = true })
        end,
        mode = { 'v' },
      },
    },
  },
}
