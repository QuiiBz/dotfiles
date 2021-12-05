local actions = require("telescope.actions")

require'telescope'.setup {
  defaults = {
    file_ignore_patterns = {
      "node_modules/*",
      ".git/*"
    },
    mappings = {
      i = {
        ["<esc>"] = actions.close
      },
    },
  }
}

