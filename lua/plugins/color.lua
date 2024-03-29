return {
  -- Color of choice. Now nord style
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    opts = {
      background = "dark" ,
      gruvbox_material_background = "hard",
    },
    config = function()
      vim.g.gruvbox_material_transparent_background = 1
      vim.cmd("colorscheme gruvbox-material")
    end,
  }
}
