require('dressing').setup({
  input = {
    default_prompt = "➤ ",
    anchor = "SW",
    relative = "cursor",
    row = 0,
    col = 0,
    border = "single",
    prefer_width = 40,
    max_width = nil,
    min_width = 20,
    get_config = nil,
  },
  select = {
    backend = { "telescope" },
    telescope = {
      -- can be 'dropdown', 'cursor', or 'ivy'
      theme = "cursor",
    },
    get_config = nil,
  },
})
