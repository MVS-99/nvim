return{
    {"vhyrro/luarocks.nvim",
      priority = 1001,
      config = true,
      opts = {
        rocks = { "magick" },
      },
    },
    {"nvim-neorg/neorg",
      dependencies = { "luarocks.nvim" },
      lazy = false,
      version = "*", -- Latest stable release
      config = true
    }
}
