return {
  {
    'tversteeg/registers.nvim',
    config = function()
      require('registers').setup({
        window = {
          border = 'rounded',
        },
      })
    end
  }
}
