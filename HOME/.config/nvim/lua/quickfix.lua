local devicons = require('nvim-web-devicons')

-- Set up custom quickfix window formatting
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  group = vim.api.nvim_create_augroup('custom-quickfix', { clear = true }),
  callback = function(event)
    local buf = event.buf

    -- Configure buffer options
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'cursorcolumn', false)

    -- Set up virtual text for better formatting
    local ns = vim.api.nvim_create_namespace('quickfix_custom')

    -- Buffer-local caches (cleaned up when buffer is closed)
    local icon_cache = {}
    local qf_cache = {}
    local qf_cache_version = 0

    local function get_cached_icon(filename, ext)
      local key = filename .. '.' .. (ext or '')
      if not icon_cache[key] then
        local icon, icon_hl = devicons.get_icon(filename, ext, { default = true })
        icon_cache[key] = {
          icon = icon or '󰈚',
          icon_hl = icon_hl or 'DevIconDefault'
        }
      end
      return icon_cache[key].icon, icon_cache[key].icon_hl
    end

    local function get_cached_qf_list()
      local current_version = vim.fn.getqflist({ changedtick = 0 }).changedtick
      if qf_cache_version ~= current_version then
        qf_cache = vim.fn.getqflist()
        qf_cache_version = current_version
      end
      return qf_cache
    end

    local function format_qf_entries()
      local qf_list = get_cached_qf_list()
      local formatted_entries = {}

      for i, item in ipairs(qf_list) do
        if item.bufnr ~= 0 then
          local bufname = vim.fn.bufname(item.bufnr)
          if bufname ~= '' then
            local filename = vim.fn.fnamemodify(bufname, ':t')
            local ext = vim.fn.fnamemodify(filename, ':e')
            local icon, icon_hl = get_cached_icon(filename, ext)

            local line_part = item.lnum > 0 and (':' .. item.lnum) or ''
            local content = item.text and (' ' .. item.text:gsub('^%s+', '')) or ''

            formatted_entries[i] = {
              icon = icon,
              icon_hl = icon_hl,
              filename = filename,
              line_part = line_part,
              content = content
            }
          end
        end
      end

      return formatted_entries
    end

    local function update_qf_display()
      -- Get all formatted entries at once
      local formatted_entries = format_qf_entries()
      local new_lines = {}

      -- Build new buffer content with formatting
      for i, formatted in pairs(formatted_entries) do
        local line = formatted.icon .. ' ' .. formatted.filename .. formatted.line_part .. formatted.content
        new_lines[i] = line
      end

      -- Fill in any missing lines with original content
      local original_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for i = 1, #original_lines do
        if not new_lines[i] then
          new_lines[i] = original_lines[i]
        end
      end

      -- Replace buffer content (disable LSP tracking to prevent sync errors)
      local clients = vim.lsp.get_active_clients({ bufnr = buf })
      for _, client in ipairs(clients) do
        vim.lsp.buf_detach_client(buf, client.id)
      end

      vim.api.nvim_buf_set_option(buf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)

      -- Apply syntax highlighting with extmarks
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      for i, formatted in pairs(formatted_entries) do
        -- Icon highlighting
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
          end_col = #formatted.icon + 1,
          hl_group = formatted.icon_hl
        })

        -- Filename highlighting (blue)
        local filename_start = #formatted.icon + 1
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, filename_start, {
          end_col = filename_start + #formatted.filename,
          hl_group = 'Function'
        })

        -- Line number highlighting (gray)
        if #formatted.line_part > 0 then
          local line_start = filename_start + #formatted.filename
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, line_start, {
            end_col = line_start + #formatted.line_part,
            hl_group = 'Comment'
          })
        end

        -- Content highlighting (white/normal)
        if #formatted.content > 0 then
          local content_start = filename_start + #formatted.filename + #formatted.line_part
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, content_start, {
            end_col = content_start + #formatted.content,
            hl_group = 'Normal'
          })
        end
      end
    end

    vim.schedule(update_qf_display)

    -- Update when quickfix list changes
    vim.api.nvim_create_autocmd({ 'QuickFixCmdPost' }, {
      callback = function()
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            update_qf_display()
          end
        end)
      end,
    })

    -- Adjust cursor position to avoid icon overlap
    vim.keymap.set('n', '<CR>', function()
      local line = vim.api.nvim_win_get_cursor(0)[1]
      vim.cmd('cc ' .. line)
    end, { buffer = buf, silent = true })

    -- Move cursor to avoid icon area
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = buf,
      callback = function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local col = cursor[2]
        -- Ensure cursor is positioned after the icon (column 2 or more)
        if col < 2 then
          vim.api.nvim_win_set_cursor(0, { cursor[1], 2 })
        end
      end,
    })
  end,
})

function ToggleQuickfix()
  local windows = vim.fn.getwininfo()
  for _, win in ipairs(windows) do
    if win.quickfix == 1 then
      vim.cmd('cclose')
      return
    end
  end
  vim.cmd('copen')
end

-- Toggle quickfix list
vim.keymap.set('n', '<leader>q', ToggleQuickfix, { noremap = true, silent = true })

-- Go to next/previous item in quickfix list
vim.cmd('nnoremap <silent> <leader>n :cnext<CR>')
vim.cmd('nnoremap <silent> <leader>p :cprev<CR>')
