return {
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local function diff_source()
        local gitsigns = vim.b.gitsigns_status_dict
        if gitsigns then
          return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed
          }
        end
      end
      require('lualine').setup{
        sections = {
          lualine_a = {'mode'},
          lualine_b = { {'diff', source = diff_source}, },
          lualine_c = { 'filename' },
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        extensions = {"neo-tree", "trouble", "lazy", "mason"},
        options = {
          theme = "tokyonight"
        }
      }
    end,
}
