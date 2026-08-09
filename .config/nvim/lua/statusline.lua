local M = {}

local function shorten_path(path, separator, maximum_length)
  if #path <= maximum_length then
    return path
  end

  local segments = vim.split(path, separator, { plain = true })
  local path_length = #path
  for i = 1, #segments - 1 do
    if path_length <= maximum_length then
      break
    end

    local segment = segments[i]
    local shortened = segment:sub(1, vim.startswith(segment, '.') and 2 or 1)
    segments[i] = shortened
    path_length = path_length - (#segment - #shortened)
  end

  return table.concat(segments, separator)
end

function M.filename()
  local filename = vim.fn.expand('%:~:.')
  if filename == '' or filename:match('^[%a][%w+.-]*://') then
    return ''
  end

  return shorten_path(filename, package.config:sub(1, 1), vim.o.columns - 40) .. ' '
end

local function search_count()
  if vim.v.hlsearch == 0 then
    return ''
  end

  local success, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 500 })
  if not success or next(result) == nil then
    return ''
  end

  return string.format('%d/%d', result.current, math.min(result.total, result.maxcount))
end

local function recording_register()
  local register = vim.fn.reg_recording()
  return register == '' and '' or '@' .. register
end

function M.right()
  local components = vim.tbl_filter(function(component)
    return component ~= ''
  end, { search_count(), recording_register() })
  local status = table.concat(components, '   ')
  local lsp_status = vim.lsp.status()

  if lsp_status ~= '' then
    lsp_status = lsp_status:gsub('%%', '%%%%')
    local separator = status == '' and '' or '   '
    status = status .. separator .. '%#Comment#' .. lsp_status .. '%*'
  end

  return ' ' .. status .. ' '
end

vim.o.laststatus = 3
vim.o.statusline = " %<%{v:lua.require'statusline'.filename()}%=%{%v:lua.require'statusline'.right()%}"

vim.api.nvim_create_autocmd({ 'RecordingEnter', 'RecordingLeave', 'LspProgress' }, {
  group = vim.api.nvim_create_augroup('statusline', { clear = true }),
  callback = function()
    vim.cmd.redrawstatus()
  end,
})

return M
