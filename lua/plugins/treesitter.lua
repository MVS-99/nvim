return{
  -- Treesitter is a parser generator tool
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")
      configs.setup({
        ensure_installed = {"c", "lua", "vim", "vimdoc", "query",
          "cpp", "regex", "rust", "asm", "python", "html"},
        sync_install = false,
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  }
}
