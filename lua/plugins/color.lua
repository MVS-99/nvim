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
      vim.cmd("colorscheme gruvbox-material")
    end,
  }
}
