return{
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  dependencies = {'nvim-lua/plenary.nvim'},
  config = function()
    local builtin = require("telescope.builtin")
    vim.keymap.set('n', '<leader>tff', builtin.find_files, {})
    vim.keymap.set('n', '<leader>tfg', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>tfb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>tfh', builtin.help_tags, {})
  end,
}
