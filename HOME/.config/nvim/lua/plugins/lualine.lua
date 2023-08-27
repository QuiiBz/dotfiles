return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'linrongbin16/lsp-progress.nvim',
    },
    init = function()
      vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
      vim.api.nvim_create_autocmd("User LspProgressStatusUpdated", {
          group = "lualine_augroup",
          callback = require("lualine").refresh,
      })
    end,
    config = function()
      local function LspStatus()
        return require("lsp-progress").progress({
          format = function(messages)
            return #messages > 0 and table.concat(messages, " ") or ""
          end,
        })
      end

      require('lualine').setup({
        options = {
          component_separators = '|',
          section_separators = { left = '', right = '' },
          globalstatus = true,
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch'},
          lualine_c = {'diff', LspStatus},
          lualine_x = {},
          lualine_y = {'filetype'},
          lualine_z = {'progress'}
        },
        inactive_sections = {},
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      })
    end,
  }
}
