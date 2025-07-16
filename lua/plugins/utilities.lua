return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
	},
	{
		"kylechui/nvim-surround",
		version = "^3.0.0", -- Use for stability; default is main
		event = "VeryLazy",
		config = true,
	},
}
