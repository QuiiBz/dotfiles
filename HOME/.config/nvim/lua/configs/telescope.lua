local actions = require("telescope.actions")

require'telescope'.setup {
  extensions = {
    fzf = {
      fuzzy = false,                   -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  },
  defaults = {
    file_ignore_patterns = {
      "node_modules/*",
      ".git/*",
      ".next/*",
      ".dist/*",
      "dist/*",
      "out/*"
    },
    mappings = {
      i = {
        ["<esc>"] = actions.close
      },
    },
  },
  pickers = {
    find_files = {
      hidden = true,
    }
  }
}

require('telescope').load_extension('fzf')
