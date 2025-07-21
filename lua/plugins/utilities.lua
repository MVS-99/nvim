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
	{
		"ggandor/leap.nvim",
		dependencies = { "tpope/vim-repeat" },
		opts = {
			-- Exclude whitespace and the middle of alphabetic words from preview:
			--   foobar[baaz] = quux
			--   ^----^^^--^^-^-^--^
			preview_filter = function(ch0, ch1, ch2)
				return not (ch1:match("%s") or ch0:match("%s") and ch1:match("%a") and ch2:match("%a"))
			end,
			-- Define equivalence classes for brackets and quotes, in addition
			-- to the default whitespace group
			equivalence_classes = { " \t\r\n", "([{", ")]}", "'\"`" },
		},
	},
}
