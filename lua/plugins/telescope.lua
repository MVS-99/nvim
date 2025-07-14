return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local builtin = require("telescope.builtin")
		vim.keymap.set(
			"n",
			"<leader>tff",
			builtin.find_files,
			{ desc = "Lists files in your current working directory, respects .gitignore" }
		)
		vim.keymap.set(
			"n",
			"<leader>tgf",
			builtin.git_files,
			{ desc = "Fuzzy search through the output of git ls-files command, respects .gitignore" }
		)
		vim.keymap.set("n", "<leader>tgs", function()
			local word = vim.fn.expand("<cword>")
			builtin.grep_string({ search = word })
		end, { desc = "Searches for the string under your cursor or selection in your current working directory" })
		vim.keymap.set("n", "<leader>tgS", function()
			local word = vim.fn.expand("<cWORD>")
			builtin.grep_string({ search = word })
		end, { desc = "Searches for the string under your cursor or selection in your current working directory" })
		vim.keymap.set("n", "<leader>tGs", function()
			builtin.grep_string({ search = vim.fn.input("Grep > ") })
		end, { desc = "Searches for the string under your cursor or selection in your current working directory" })
		vim.keymap.set("n", "<leader>tfb", builtin.buffers, { desc = "Lists open buffers in current neovim instance" })
		vim.keymap.set(
			"n",
			"<leader>tht",
			builtin.help_tags,
			{ desc = "Lists available help tags and opens a new window with the relevant help info on <cr>" }
		)
		vim.keymap.set(
			"n",
			"<leader>tmp",
			builtin.man_pages,
			{ desc = "Lists manpage entries, opens them in a help window on <cr>" }
		)
	end,
}
