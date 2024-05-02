return{
  'nvim-telescope/telescope.nvim',
  tag = '0.1.6',
  dependencies = {'nvim-lua/plenary.nvim'},
  config = function()
    local builtin = require("telescope.builtin")
    vim.keymap.set('n', '<leader>tff', builtin.find_files, {})
    vim.keymap.set('n', '<leader>tfg', builtin.git_files, {})
    vim.keymap.set('n', '<leader>tgs', function ()
      local word = vim.fn.expand("<cword>")
      builtin.grep_string({ search = word })
    end)
    vim.keymap.set('n', '<leader>tgS', function ()
      local word = vim.fn.expand("<cWORD>")
      builtin.grep_string({ search = word })
    end)
    vim.keymap.set('n', '<leader>tGs', function ()
      builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end)
    vim.keymap.set('n', '<leader>tfb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>tht', builtin.help_tags, {})
  end,
}
