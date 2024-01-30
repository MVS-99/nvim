return {
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local navic = require("nvim-navic")
      require('lualine').setup{
          sections = {
            lualine_a = {'mode'},
            lualine_b = {'branch', 'diff', 'diagnostics'},
            lualine_c = {
              {function ()
                return navic.get_location()
              end,
              cond = function ()
                return navic.is_available()
              end
              },
            },
            lualine_x = {'encoding', 'fileformat', 'filetype'},
            lualine_y = {'progress'},
            lualine_z = {'location'}
          },
          extensions = {"neo-tree", "trouble", "lazy", "mason"}
      }
    end,
}
