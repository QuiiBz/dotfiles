local preview_layout = {
  layout = {
    box = 'vertical',
    backdrop = false,
    row = -1,
    width = 0,
    height = 0.5,
    border = 'top',
    wo = {
      winhighlight = 'NormalFloat:NormalFloat,FloatBorder:WinSeparator,FloatTitle:FloatTitle',
    },
    title = ' {title} {live} {flags}',
    title_pos = 'left',
    { win = 'input', height = 1, border = 'none' },
    {
      box = 'horizontal',
      { win = 'list', border = 'none' },
      {
        win = 'preview',
        title = '{preview}',
        width = 0.4,
        border = 'left',
        wo = {
          winhighlight = 'NormalFloat:NormalFloat,FloatBorder:WinSeparator,FloatTitle:FloatTitle',
        },
      },
    },
  },
}

local list_layout = {
  layout = {
    box = 'vertical',
    backdrop = false,
    row = -1,
    width = 0,
    height = 8,
    border = 'top',
    wo = {
      winhighlight = 'NormalFloat:NormalFloat,FloatBorder:WinSeparator,FloatTitle:FloatTitle',
    },
    title = ' {title} {live} {flags}',
    title_pos = 'left',
    { win = 'input', height = 1, border = 'none' },
    { win = 'list', height = 0, border = 'none' },
  },
}

local function is_git_repo()
  vim.fn.system({ 'git', '-C', vim.fn.getcwd(), 'rev-parse', '--is-inside-work-tree' })
  return vim.v.shell_error == 0
end

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    keys = {
      {
        '<C-p>',
        function()
          Snacks.picker.files({ hidden = true, layout = preview_layout })
        end,
      },
      {
        '<C-f>',
        function()
          -- Use git grep as it's significantly faster than ripgrep for large projects,
          -- with fallback to ripgrep if not in a git repo
          if is_git_repo() then
            Snacks.picker.git_grep({
              untracked = true,
              ignorecase = true,
              cmd_args = { '-F' }, -- disable regex
              layout = preview_layout,
            })
            return
          end

          Snacks.picker.grep({ hidden = true, regex = false, layout = preview_layout })
        end,
      },
      {
        'z=',
        function()
          Snacks.picker.spelling({ layout = list_layout })
        end,
      },
    },
    config = function(_, opts)
      require('snacks').setup(opts)

      local function attach_image(buf)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        local src = buf_name:match('^minifiles://%d+/(.+)$')
        if src then
          if not Snacks.image.supports_file(src) then
            return
          end

          -- mini.files uses a 1-line placeholder for binary files; seed more
          -- lines so its preview window keeps enough height for image rendering.
          local lines = {}
          for _ = 1, math.max(10, vim.o.lines - vim.o.cmdheight - 4) do
            lines[#lines + 1] = ''
          end
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
          vim.bo[buf].modified = false

          Snacks.image.buf.attach(buf, { src = src })
          return
        end

        Snacks.image.buf.attach(buf)
      end

      -- Fix images in buffers disappearing after switching away and back
      vim.api.nvim_create_autocmd('BufWinEnter', {
        group = vim.api.nvim_create_augroup('snacks-image-reattach', { clear = true }),
        pattern = '*.' .. table.concat(Snacks.image.config.formats, ',*.'),
        callback = function(event)
          attach_image(event.buf)
        end,
      })

      -- Add image preview in mini.files
      vim.api.nvim_create_autocmd('User', {
        group = 'snacks-image-reattach',
        pattern = 'MiniFilesBufferUpdate',
        callback = function(event)
          local buf = event.data and event.data.buf_id
          if not buf then
            return
          end
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              attach_image(buf)
            end
          end)
        end,
      })
    end,
    opts = {
      lazygit = {
        enabled = true,
        configure = false,
        win = {
          height = 0.98,
          width = 0.98,
        },
      },
      bigfile = {
        enabled = true,
        notify = false,
        size = 1024 * 300, -- 300kB
      },
      image = {},
      picker = {
        prompt = ' ',
        sources = {
          select = {
            layout = list_layout,
          },
        },
        limit_live = 1000,
        matcher = {
          fuzzy = true,
          smartcase = true,
          frecency = true,
        },
        win = {
          input = {
            keys = {
              ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
              ['<S-Tab>'] = { 'select_and_prev', mode = { 'i', 'n' } },
              ['<Tab>'] = { 'select_and_next', mode = { 'i', 'n' } },
            },
          },
        },
        formatters = {
          file = {
            truncate = 90, -- default is 60
          },
        },
      },
      input = {
        icon = '',
        win = {
          title_pos = 'left',
          relative = 'cursor',
          row = 1,
          wo = {
            winhighlight = 'NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle',
          },
          keys = {
            i_esc = { '<esc>', { 'cmp_close', 'cancel' }, mode = 'i', expr = true },
          },
        },
      },
    },
  },
}
