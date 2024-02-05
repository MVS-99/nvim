return{
  {"TobinPalmer/Tip.nvim",
  event = "VimEnter",
  init = function()
    -- Default config
    --- @type Tip.config
    require("tip").setup({
      seconds = 2,
      title = "Tip!",
      url = "https://www.vimiscool.tech/neotip",
    })
  end},
  {"rcarriga/nvim-notify"}
}
