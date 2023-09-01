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
          starter.sections.recent_files(5, false, false),
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
