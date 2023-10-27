return {
  {
    'echasnovski/mini.starter',
    config = function()
      local starter = require('mini.starter')
      starter.setup({
        items = {
          function()
            return {
              {
                name = 'Load session (directory)',
                action = function()
                  require('persistence').load()
                end,
                section = 'Session'
              },
              {
                name = 'Load last session',
                action = function()
                  require('persistence').load({ last = true })
                end,
                section = 'Session'
              },
            }
          end,
          function()
            return {
              {
                name = 'Find files',
                action = function()
                  require('telescope.builtin').git_files({ silent = true })
                end,
                section = 'Files',
              },
              {
                name = 'Search in files',
                action = function()
                  require('telescope.builtin').live_grep({ silent = true })
                end,
                section = 'Files',
              }
            }
          end,
          starter.sections.builtin_actions(),
        },
        content_hooks = {
          starter.gen_hook.adding_bullet(),
          starter.gen_hook.aligning('center', 'center'),
        },
        footer = '',
      })
    end
  }
}
